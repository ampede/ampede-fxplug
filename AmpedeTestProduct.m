//
//  AmpedeTestProduct.m
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "AmpedeTestProduct.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Security/Security.h>

#import "DSMacros.h"

Class AmpedeProductManager = Nil;

int read( long, StringPtr, int);
int write( long, StringPtr, int);
 
OSStatus
LaunchBackgroundAppWithURL( NSURL *appURL )
{
	LSLaunchURLSpec launchSpec = { NULL
                                 , NULL
                                 , NULL
                                 , kLSLaunchDontAddToRecents | kLSLaunchDontSwitch
                                 , NULL
                                 } ;

	launchSpec.appURL = (CFURLRef)appURL;

    return LSOpenFromURLSpec( &launchSpec, NULL );
}

OSStatus
InstallAmpedeFxPlugFrameworkFromAbsolutePath( NSString *frameworkPath )
{
    OSStatus myStatus;
    AuthorizationRef myAuthorizationRef;
 
    myStatus = AuthorizationCreate( NULL
                                  , kAuthorizationEmptyEnvironment
                                  , kAuthorizationFlagDefaults
                                  , &myAuthorizationRef            );
                                  
    if ( myStatus == errAuthorizationSuccess )
    {
        AuthorizationItem myItems = { kAuthorizationRightExecute
                                    , 0
                                    , NULL
                                    , 0
                                    } ;
                                    
        AuthorizationRights myRights = { 1
                                       , &myItems
                                       } ;
 
        myStatus = AuthorizationCopyRights( myAuthorizationRef
                                          , &myRights
                                          , NULL
                                          , kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights
                                          , NULL                                                                                                                                );
 
        if ( myStatus == errAuthorizationSuccess )
        {
            printf( "\n====================================================================================\n" );
            printf( "  Beginning installation of the AmpedeFxPlug.framework in /Library/Frameworks/ ...\n" );
            printf( "====================================================================================\n\n" );
            fflush( stdout );
            
            char myToolPath[] = "/usr/bin/rsync";
            char *myArguments[] = { "-avE", (char *)[frameworkPath cString], "/Library/Frameworks/", NULL };
            
            FILE *myCommunicationsPipe = NULL;
            unsigned char myReadBuffer[ 128 ];
 
            myStatus = AuthorizationExecuteWithPrivileges( myAuthorizationRef
                                                         , myToolPath
                                                         , kAuthorizationFlagDefaults
                                                         , myArguments
                                                         , &myCommunicationsPipe      );
 
            if ( myStatus == errAuthorizationSuccess )
            {
                int bytesRead = 0;
                for ( ;; )
                {
                    bytesRead = read( fileno( myCommunicationsPipe )
                                    , myReadBuffer
                                    , sizeof( myReadBuffer )       );
                                    
                    if ( bytesRead < 1 ) break;
                    
                    write( fileno( stdout )
                         , myReadBuffer
                         , bytesRead      );
                }
            }
            else
            {
                printf( "Ampede Error: AuthorizationExecuteWithPrivileges() call failed. Reason: %ld\n", myStatus );
                fflush( stdout );
            }
            printf( "\n====================================================================================\n" );
            printf( "  Ending installation of the AmpedeFxPlug.framework\n" );
            printf( "====================================================================================\n\n" );
            fflush( stdout );
        }

    }
    
    AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
    
    if ( myStatus ) NSLog( @"Ampede Error: The AmpedeFxPlug.framework installation failed. Reason: %ld", myStatus );
    
    return myStatus;
}

@implementation AmpedeTestProduct

- init
{
    LOG
    
    if ( self = [super init] )
    {
        pluginInfoPlists = [[NSMutableArray alloc] init];
        
        NSString *pluginsDirectoryPath = [[NSBundle bundleForClass: [self class]] builtInPlugInsPath];
        NSDirectoryEnumerator *pluginsDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath: pluginsDirectoryPath];
        
        foreacht( NSString*, pluginRelativePath, pluginsDirectoryEnumerator )
        {
            [pluginsDirectoryEnumerator skipDescendents]; // we only care about top-level directories in the PlugIns folder
            
            if ( [[pluginRelativePath pathExtension] isEqualToString: @"plugin"] )
            {
                NSString *pluginPath = [pluginsDirectoryPath stringByAppendingPathComponent: pluginRelativePath];
                NSBundle *pluginBundle = [NSBundle bundleWithPath: pluginPath];
                NSDictionary *pluginInfoPlist = [pluginBundle infoDictionary];
                
                if ( pluginInfoPlist ) [pluginInfoPlists addObject: pluginInfoPlist];
            }
        }
        
        LOGO( pluginInfoPlists );
        
        // This is where we load our product's shared, embedded, license-controlled application.
        NSLog( @"Ampede: Launching the LC'd app now." );
        
        // Register for the AmpedeProductManager notifications
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector:    @selector( registerAmpedePlugIns: )
                                              name:        @"DSAmpedeProductManagerRegisterPlugInsNotification"
                                              object:      nil                                                ];
        
        
    }
    return self;
}

- (void) dealloc
{
    release( pluginInfoPlists );
    
    [super dealloc];
}

- (NSArray *)
registerPlugInItemsWithKey: (NSString *) key
{
    // This is where we set up any plugin groups.
    NSMutableArray *registerItems = [NSMutableArray array];
    
    foreacht( NSDictionary*, pluginInfoPlist, pluginInfoPlists )
    {
        NSArray *pluginItems = [pluginInfoPlist valueForKey: key];
        
        if ( pluginItems ) [registerItems addObjectsFromArray: pluginItems];
    }
    
    LOGO( registerItems );
    
    return registerItems;
}

- (void) registerAmpedePlugIns: (NSNotification *) note
{
    LOG
    
    id productManager = [note object];
    
    foreacht( NSDictionary*, pluginInfoPlist, pluginInfoPlists )
    {
        [productManager registerPlugInInfoPlist: pluginInfoPlist];
    }
}

#pragma mark -
#pragma mark PROPlugInRegistering protocol

+ sharedInstance
{
    LOG
    
    static id sharedInstance = nil;
    
    if ( !sharedInstance ) sharedInstance = [[self alloc] init];

    return sharedInstance;
}

//
//  Accept or refuse to be loaded.
//

- (BOOL)
shouldLoadFirstInstanceOfPlugInWithError: (NSError **) error
{
    LOG
    
    static BOOL isInitialized = NO;
    static BOOL pluginsLoaded = NO;
    
    if ( !isInitialized )
    {
        isInitialized = YES;
        
        BOOL ampedeFxPlugFrameworkWasAlreadyLoaded = NO;
        BOOL installedAmpedeFxPlugFramework = NO;
        
        //
        // Install the embedded AmpedeFxPlug.framework to /Library/Frameworks/ if it is missing, corrupt, or outdated.
        //
        
        AmpedeProductManager = NSClassFromString( @"AmpedeProductManagerWeak" );
        
        if ( AmpedeProductManager != NULL ) ampedeFxPlugFrameworkWasAlreadyLoaded = YES;
        
        NSString *sharedFrameworksPath = [[NSBundle bundleForClass: [self class]] sharedFrameworksPath];
        NSString *embeddedFrameworkPath = [[sharedFrameworksPath stringByAppendingPathComponent: @"AmpedeFxPlug.framework"] stringByStandardizingPath];
        
        NSDictionary *infoPlist = [[NSBundle bundleForClass: [self class]] infoDictionary];
        NSString *majorVersion = [infoPlist valueForKey: @"DSAmpedeFxPlugFrameworkMajorVersion"];
        NSNumber *minorCurrentVersion = [NSNumber numberWithInt: [[infoPlist valueForKey: @"DSAmpedeFxPlugFrameworkMinorCurrentVersion"] intValue]];
        
        if ( majorVersion && minorCurrentVersion )
        {
            NSString *frameworkInstallPath = [NSString stringWithFormat: @"/Library/Frameworks/AmpedeFxPlug.framework/Versions/%@", majorVersion];
            BOOL pathExists = NO;
            BOOL pathIsDirectory = NO;
            pathExists = [[NSFileManager defaultManager] fileExistsAtPath: frameworkInstallPath
                                                         isDirectory:      &pathIsDirectory    ];
            
            if ( pathExists && pathIsDirectory )
            {
                NSString *frameworkPlistPath = [NSString stringWithFormat: @"/Library/Frameworks/AmpedeFxPlug.framework/Versions/%@/Resources/Info.plist", majorVersion];
                
                pathExists = [[NSFileManager defaultManager] fileExistsAtPath: frameworkPlistPath];
                
                if ( pathExists )
                {
                    NSDictionary *existingInfoPlist = [NSDictionary dictionaryWithContentsOfFile: frameworkPlistPath];
                    NSNumber *existingMinorCurrentVersion = [NSNumber numberWithInt: [[existingInfoPlist valueForKey: @"DSAmpedeFxPlugFrameworkMinorCurrentVersion"] intValue]];
                    
                    if ( !existingMinorCurrentVersion || [existingMinorCurrentVersion isLessThan: minorCurrentVersion] )
                    {
                        OSStatus installStatus;
                        int alertReturn = NSRunAlertPanel( @"Your AmpedeFxPlug.framework installation is outdated."
                                                         , @"This framework is required by all Ampede plugins. Would you like to update it now?"
                                                         , @"Update"
                                                         , @"Update and View Log..."
                                                         , @"Cancel"
                                                         ) ;
                        switch ( alertReturn )
                        {
                            case NSAlertDefaultReturn:
                                installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                                break;
                            case NSAlertAlternateReturn:
                                installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                                system( "/usr/bin/open -b com.apple.Console" ); // /Applications/Utilities/Console.app
                                break;
                            default:
                                NSLog( @"Ampede: User canceled the AmpedeFxPlug.framework update." );
                                break;
                        }
                
                        if ( installStatus == errAuthorizationSuccess ) installedAmpedeFxPlugFramework = YES;
                    }
                }
                else
                {
                    OSStatus installStatus;
                    int alertReturn = NSRunAlertPanel( @"Your AmpedeFxPlug.framework installation is corrupt."
                                                     , @"This framework is required by all Ampede plugins. Would you like to repair it now?"
                                                     , @"Repair"
                                                     , @"Repair and View Log..."
                                                     , @"Cancel"
                                                     ) ;
                    switch ( alertReturn )
                    {
                        case NSAlertDefaultReturn:
                            installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                            break;
                        case NSAlertAlternateReturn:
                            installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                            system( "/usr/bin/open -b com.apple.Console" ); // /Applications/Utilities/Console.app
                            break;
                        default:
                            NSLog( @"Ampede: User canceled the AmpedeFxPlug.framework repair." );
                            break;
                    }
                
                    if ( installStatus == errAuthorizationSuccess ) installedAmpedeFxPlugFramework = YES;
                }
            }
            else
            {
                OSStatus installStatus;
                int alertReturn = NSRunAlertPanel( @"The AmpedeFxPlug.framework has not been installed."
                                                 , @"This framework is required by all Ampede plugins. Would you like to install it now?"
                                                 , @"Install"
                                                 , @"Install and View Log..."
                                                 , @"Cancel"
                                                 ) ;
                switch ( alertReturn )
                {
                    case NSAlertDefaultReturn:
                        installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                        break;
                    case NSAlertAlternateReturn:
                        installStatus = InstallAmpedeFxPlugFrameworkFromAbsolutePath( embeddedFrameworkPath );
                        system( "/usr/bin/open -b com.apple.Console" ); // /Applications/Utilities/Console.app
                        break;
                    default:
                        NSLog( @"Ampede: User canceled the AmpedeFxPlug.framework installation." );
                        break;
                }
                
                if ( installStatus == errAuthorizationSuccess ) installedAmpedeFxPlugFramework = YES;
            }
        }
        
        if ( ampedeFxPlugFrameworkWasAlreadyLoaded && installedAmpedeFxPlugFramework )
        {
            // we'll need to relaunch to get the benefits of the new framework
            int alertReturn = NSRunAlertPanel( @"The AmpedeFxPlug.framework was installed."
                                             , @"Due to a previous installation of the framework, you must relaunch to load the Ampede plugins. Would you like to relaunch now?"
                                             , @"Relaunch"
                                             , @"Cancel"
                                             , nil
                                             ) ;
            switch ( alertReturn )
            {
                case NSAlertDefaultReturn:
                    setenv("RELAUNCH_PATH", [[[NSBundle mainBundle] bundlePath] UTF8String], 1);
                    system("/bin/bash -c '{ for (( i = 0; i < 3000 && $(echo $(/bin/ps -xp $PPID|/usr/bin/wc -l))-1; i++ )); do\n"
                           "    /bin/sleep .2;\n"
                           "  done\n"
                           "  if [[ $(/bin/ps -xp $PPID|/usr/bin/wc -l) -ne 2 ]]; then\n"
                           "    /usr/bin/open \"${RELAUNCH_PATH}\"\n"
                           "  fi\n"
                           "} &>/dev/null &'");
                           
                    [NSApp terminate:self];	
                    break;
                default:
                    break;
            }
        }
        
        //
        // Load our plugins into memory.
        //
        
        BOOL loadedFramework = [[NSBundle bundleWithPath: @"/Library/Frameworks/AmpedeFxPlug.framework"] load];
        
        AmpedeProductManager = NSClassFromString( @"AmpedeProductManagerWeak" );
        
        if ( loadedFramework && AmpedeProductManager != NULL )
        {
            id productManager = [AmpedeProductManager productManager]; // this indirectly calls all product's -registerAmpedePlugIns: method (including us)
            
            foreacht( NSDictionary*, pluginInfoPlist, pluginInfoPlists )
            {
                NSString *bundleIdentifier = [pluginInfoPlist valueForKey: @"CFBundleIdentifier"];
                
                if ( bundleIdentifier && ![productManager loadPlugInWithBundleIdentifier: bundleIdentifier] )
                {
                    NSString *pluginPath = [pluginInfoPlist valueForKey: @"NSBundleResolvedPath"];
                    NSLog( @"Ampede Error: Plugin bundle failed to load. {\n     Path: %@\n     BundleIdentifier: %@\n}", pluginPath, bundleIdentifier );
                }
            }
            
            pluginsLoaded = YES;
        }
        else
        {
            if ( !loadedFramework )
            {
                NSLog( @"Ampede Error: Plugins were not loaded. Reason: the AmpedeFxPlug.framework did not load." );
                NSRunAlertPanel( @"The AmpedeFxPlug.framework could not be loaded."
                               , @"This framework is required by all Ampede plugins. Any Ampede plugins will be disabled in this Motion session."
                               , @"OK"
                               , nil
                               , nil
                               ) ;
            }
            else if ( AmpedeProductManager == NULL )
            {
                NSLog( @"Ampede Error: Plugins were not loaded. Reason: the AmpedeProductManagerWeak class was not found." );
                NSRunAlertPanel( @"The installed AmpedeFxPlug.framework is corrupt."
                               , @"This framework is required by all Ampede plugins. Any Ampede plugins will be disabled in this Motion session."
                               , @"OK"
                               , nil
                               , nil
                               ) ;
            }

            pluginsLoaded = NO;
        }
    }
    
    return pluginsLoaded;
}

- (NSArray *)
requestedProtocolsWithError: (NSError **) error
{
    LOG
    
    // This is where we set up any plugin groups.
    return [self registerPlugInItemsWithKey: @"ProPlugProtocolList"];
}

//
//  Dynamically register any plug-in groups here by returning an array of NSDictionaries mirroring the structure found in property lists.
//  This return value will override any plug-ins found in the Info.plist. If returning nil, error should be filled with an appropriately
//  illuminating error object.
//

- (NSArray *)
registeredPlugInGroupsWithError: (NSError **) error
{
    LOG
    
    // This is where we set up any plugin groups.
    return [self registerPlugInItemsWithKey: @"ProPlugPlugInGroupList"];
}

//
//  Dynamically register any plug-ins here by returning an array of NSDictionaries mirroring the structure found in property lists.
//  This return value will override any plug-ins found in the Info.plist. If returning nil, error should be filled with an appropriately
//  illuminating error object.
//

- (NSArray *)
registeredPlugInsWithError: (NSError **) error
{
    // This is where we register the plugins for this host application found in our PlugIns directory.
    // If any plugin has been previously loaded, we ask that plugin to re-register with its license-controlled application.
    //
    // When a plugin is asked to register, it asks us for the DO registration names, which are returned in the order they should be tried.
    // These names are stored in a dictionary defined and managed in this class, and must be registered as such.
    // This insures that each plugin register with the most capable licensed plugin-suite first.
    //
    // In addition, plugins should ask this class when the user requests a registration, so the user can be pointed at the correct plugin
    // suite to register.
    
    LOG
    
    return [self registerPlugInItemsWithKey: @"ProPlugPlugInList"];
}

@end
