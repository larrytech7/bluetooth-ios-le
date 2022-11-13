

import Foundation


protocol BLEProtocol {
    
    func disconnected(message: String)
    func failConnected(message: String)
    func connected(message: String)
    func valueRead(message: String)
    func valueWrite(message: String)

}
