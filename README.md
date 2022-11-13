# Bluetooth LE IOS Swift

Please note thet the purpose here is not to implement a perfect nice best design pattern, but demonstrate how to use, at the best I can, the BLE on iPhone, iPad ( and soon on Mac )

This project contains application written in Swift 5, for IOS 13 or above.

- a central manager, which will comunicate with bluetooth peripheral

# The Central manager 

This application will be able to be connected to a peripheral, read a value, write a value, be notifyed for value modified on peripheral side.
it will received the notified value in background.
it will be wake up if killed by IOS, when peripheral will notify anything in bluetooth.

This App contain a BLE stack, a BLE controller, and a view + viewcontroller.

for this example, the name or UUID is predefined, in the viewcontroller
You could create an App, using this project, which discover all device, and service, and Characteristics, and ask to the user to select which he ant to connect to...

The App will start the central, discover the services + Characteristics, connect to the peripheral, read a value, request to be notified for value update, write a value.

**Background**
App request to work in background, for Bluetooth event. for that, in info.plist, I added this :

```
	<key>UIBackgroundModes</key>
	<array>
		<string>bluetooth-central</string>
	</array>

```

This tell to IOS that we need to be called, when in background, by bluetooth event coming from a connected peripheral.
You understand that we are not managning anything : IOS will call us. it will call the delegate we ghave defined when starting the central manager, when we were connected to peripheral, when we requested to be notified for value modified by peripheral...

Note : when in background, the app does nothing : no timer, no code is running.
You can request to finish some code, before entering in 'sleep state', but this time allowed by IOS is about 3 minute max !
there is plenty of code explaining how to request this 3 minutes more, before entering in 'sleep state'.

example of code you could call, when you detect the background mode :

call registerBackgroundTask()

```
    func registerBackgroundTask() {
        appController.log("register bacground task")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }

    func endBackgroundTask() {
        appController.log("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
```

To check what is the app state :

```
    switch UIApplication.shared.applicationState {
            case .active:
            // DO something
            case .background:
            // do spomething
            case .inactive:
            // do somehting
                break
    }
```



**Long-term action in background**

Sometime, IOS decide to kill you App : to save memory, to save battery, to ???
in this case, you app does not do anything at all !
There is a way to request to be wake up by IOS, when the bluetooth device update some notified value, is disconnected from peripheral, etc...

To be able to have this behavior, we need to start the central manager, with some particular parameter :

```
        centralManager = CBCentralManager(delegate: self, queue: nil, options:[CBCentralManagerOptionRestoreIdentifierKey: "fr.ormaa.centralManager"])

```
Note : I tried to define a queue, and have no better result !

CBCentralManagerOptionRestoreIdentifierKey : tells to IOS : if you kill this App, and there is a peripheral which was connected to this central ( fr.ormaa.centralManager), wake up the app, call the appdelegate class etc...
Note : in this case, the app stay in background, nothign is displayed on screen.

when the peripheral is dosconnected, visible by ios bluetooth again, when peripheral notify some value, the App is restarted.
in my appdelegate, I added this code

```
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        singleton.logger.log("application didFinishLaunchingWithOptions")
        
        singleton.appRestored = false
        singleton.centralManagerToRestore = ""
        
        // if waked up by the system, with bluetooth identifier in parameter :
        // We need to initialize a central manager, with same name.
        // a bluetooth event accoured.
        //
        if let peripheralManagerIdentifiers: [String] = launchOptions?[UIApplicationLaunchOptionsKey.bluetoothCentrals] as? [String]{
            if peripheralManagerIdentifiers.count > 1 {
                // TODO : manage this case
            }
            if peripheralManagerIdentifiers.count == 1 {
                // only one central Manager to initialize again
                let identifier = peripheralManagerIdentifiers.first
                    
                singleton.logger.log("UIApplicationLaunchOptionsKey.bluetoothCentrals] : ")
                singleton.logger.log("App was closed by system. will restore the central manager ")
                singleton.logger.log("--> " + identifier!)

                // flag allowing to know that we need to restore the central manager
                singleton.appRestored = true
                // name of central manager to restore
                singleton.centralManagerToRestore = identifier!
            
            }
        }
        return true
    }
```

Here, we noticei that I get only string ! not central object, no peripheral object !!!
I place some flag and value, in a singleton class, to tell to the main controller : hey, the central manager need to be update, but not using the normal process !

in my main controller, here is what happen :

```
        if appDelegate!.singleton.appRestored {
            appDelegate!.singleton.bluetoothController.restoreCentralManager(viewControllerDelegate: self,
                                                                             centralName: appDelegate!.singleton.centralManagerToRestore)
        }
        
```
RestoreCentralManager will do that :

```
        centralManager = CBCentralManager(delegate: self, queue: nil, options:[CBCentralManagerOptionRestoreIdentifierKey: "fr.ormaa.centralManager"])
```

WE DO NOT call scan peripheral, or retreive peripheral !


in the centralmanager class, I have implemented this :

```
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
        log("will restore connection")
        
        if let peripheralsObject = dict[CBCentralManagerRestoredStatePeripheralsKey] {
            let peripherals = peripheralsObject as! Array<CBPeripheral>
            if peripherals.count > 0 {
                log("Peripheral found")
                
                let peripheral = peripherals[0]
                peripheral.delegate = self
                self.peripherals.append(peripheral)
                self.rssiDB.append(NSNumber())
                self.advertisementDatas.append(oneAdvertisement( array: ["none": "none"]))

                if getState(peripheral.state) == "connected" {
                    log("connection to peripheral")
                    self.connect(peripheral: peripheral)
                }
            }
        }
    }
```

when I initalize the central manager, using the same name used when I was connected to peripheral, before app xwas killed by IOS :
because I don't start any scan, I don't try to retreive peripheral : then the delegate is called.
in WillRestoreState, I can save the peripheral, the characteristics which were discovered, etc...

as you can see, it is not really clear (at least, for me) in the Apple Doc, but it is wuite easy to use in reality.

# Xcode

BE CAREFUL : when you iphone is connected to xcode, using a lightning cable, you cannot expect having some background or longtemer action behavior like you will have, when iphone is disconnected.
BUT : you can test the fact that IOS kill you app, by running you App using Xcode, then press stop.
in this case, run log viewer, and start to send value using the pripheral : you will se that the app is restarted, in background
