
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let singleton = Singleton.sharedInstance()
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

