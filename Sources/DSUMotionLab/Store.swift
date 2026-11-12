import Foundation
import Combine

struct SavedSensor: Codable {
    var name:String;var player:Int;var host:String;var port:String;var slot:Int
    var axes:AxisMap? = nil
    var bias:[Double]? = nil
    var gravity:[Double]? = nil
    var calibrated:Bool? = nil
    var flatCentered:Bool? = nil
}
@MainActor final class SensorStore:ObservableObject {
    @Published var sensors:[Sensor]=[]
    private let key="DSUMotionLab.connections.v1"
    init() {
        if let data=UserDefaults.standard.data(forKey:key),let rows=try? JSONDecoder().decode([SavedSensor].self,from:data) {
            for r in rows { let s=Sensor();s.name=r.name;s.player=r.player;s.host=r.host;s.port=r.port;s.slot=r.slot;s.axes=r.axes ?? AxisMap();if let b=r.bias,b.count==3 { s.gyroBias=SIMD3(b[0],b[1],b[2]) };if let g=r.gravity,g.count==3 { s.flatGravity=SIMD3(g[0],g[1],g[2]) };s.calibrated=r.calibrated ?? false;s.flatCentered=r.flatCentered ?? false;sensors.append(s);observe(s) }
        }
        // Start empty unless the user previously saved connections.
    }
    private var startupConnected = false
    func connectSavedOnce() {
        guard !startupConnected else { return };startupConnected=true
        for sensor in sensors where !sensor.running { sensor.connect() }
    }
    func observe(_ s:Sensor) { s.onEdit = { [weak self] in self?.save() } }
    func add() { let s=Sensor();s.player=sensors.count+1;s.name="Phone " + String(s.player);sensors.append(s);observe(s);save() }
    func remove(_ s:Sensor) { sensors.removeAll { $0.id==s.id };save() }
    func save() {
        let rows=sensors.map { SavedSensor(name:$0.name,player:$0.player,host:$0.host,port:$0.port,slot:$0.slot,axes:$0.axes,bias:[$0.gyroBias.x,$0.gyroBias.y,$0.gyroBias.z],gravity:[$0.flatGravity.x,$0.flatGravity.y,$0.flatGravity.z],calibrated:$0.calibrated,flatCentered:$0.flatCentered) }
        if let data=try? JSONEncoder().encode(rows) { UserDefaults.standard.set(data,forKey:key) }
    }
    func discovered(host:String,port:String,slot:Int) {
        if let existing=sensors.first(where: { $0.host==host && $0.port==port && ($0.slot==slot || $0.slot == -1) }) { if !existing.running { existing.connect() };return }
        let s=Sensor();s.host=host;s.port=port;s.slot=slot;s.player=sensors.count+1;s.name="Phone " + String(s.player);sensors.append(s);observe(s);save();s.connect()
    }
}
