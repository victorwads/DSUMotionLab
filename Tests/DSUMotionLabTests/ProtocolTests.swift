import XCTest
import simd
@testable import DSUMotionLab
final class ProtocolTests:XCTestCase {
    func fixture() -> Data {
        var b=[UInt8](repeating:0,count:100)
        b.replaceSubrange(0..<4,with:Array("DSUS".utf8))
        func put(_ v:UInt64,_ o:Int,_ n:Int) { for i in 0..<n { b[o+i]=UInt8(truncatingIfNeeded:v>>(8*i)) } }
        put(1001,4,2); put(84,6,2); put(12,12,4); put(0x100002,16,4); b[21]=2;b[31]=1;put(1,32,4);put(1_000_000,68,8)
        for (o,f): (Int,Float) in [(76,0.1),(80,0.2),(84,-1),(88,90),(92,0),(96,0)] { put(UInt64(f.bitPattern),o,4) }
        put(UInt64(DSU.crc(b)),8,4); return Data(b)
    }
    func testGuidedCapture() {
        var capture = MotionCapture(); var sample = DSU.decode(fixture())!
        sample.gyro = SIMD3(0,-60,0)
        for i in 0..<41 { sample.timestamp=UInt64(i)*10_000;capture.add(sample) }
        XCTAssertEqual(capture.axis,-2)
        var mixed=MotionCapture();sample.gyro=SIMD3(60,60,0)
        for i in 0..<41 { sample.timestamp=UInt64(i)*10_000;mixed.add(sample) }
        XCTAssertNil(mixed.axis)
        var noise=MotionCapture();sample.gyro=SIMD3(0.2,0.1,0)
        for i in 0..<41 { sample.timestamp=UInt64(i)*10_000;noise.add(sample) }
        XCTAssertNil(noise.axis)
    }
    func testAutomaticCalibration() {
        var c=AutoCalibration();var s=DSU.decode(fixture())!;var time:UInt64=0
        func feed(_ gyro:SIMD3<Double>,_ frames:Int) {
            for _ in 0..<frames { time += 10_000;s.timestamp=time;s.gyro=gyro;c.add(s) }
        }
        feed(.zero,130);XCTAssertEqual(c.step,0);XCTAssertTrue(c.flatMeasured);XCTAssertFalse(c.flatReady)
        feed(.zero,130);XCTAssertFalse(c.flatReady)
        c.confirmFlat();XCTAssertTrue(c.flatReady)
        feed(SIMD3(20,0,0),2);XCTAssertTrue(c.pickedUp)
        feed(.zero,110);XCTAssertEqual(c.step,1)
        for (i,gyro) in [SIMD3<Double>(0,100,0),SIMD3<Double>(-100,0,0),SIMD3<Double>(0,0,100)].enumerated() {
            feed(.zero,60);feed(gyro,60)
            XCTAssertEqual(c.step,i*2+2)
            feed(.zero,60);feed(-gyro,60)
            XCTAssertEqual(c.step,i*2+3)
        }
        XCTAssertEqual(c.result,AxisMap(x:-1,y:2,z:3))
        feed(.zero,70);XCTAssertTrue(c.previewReady)
        feed(SIMD3(100,0,0),20);XCTAssertGreaterThan(c.preview.displayed.angle,0.1)
        c=AutoCalibration();XCTAssertNil(c.result);XCTAssertEqual(c.step,0)
    }
    @MainActor func testCalibrationHandoff() {
        let sensor=Sensor();var preview=Orientation();preview.attitude=simd_quatd(angle:0.4,axis:SIMD3(1,0,0))
        sensor.applyCalibration(map:AxisMap(x:2,y:-1,z:3),bias:SIMD3(0.2,0.3,0.4),gravity:SIMD3(0,-1,0),preview:preview)
        let expected=simd_quatd(angle:Double.pi/2,axis:SIMD3(1,0,0))*preview.displayed
        XCTAssertEqual(sensor.displayRotation.real,expected.real,accuracy:0.000001)
        XCTAssertEqual(sensor.gyroBias,SIMD3(0.2,0.3,0.4))
    }
    @MainActor func testRecenterPreservesCalibration() {
        let sensor=Sensor();let map=AxisMap(x:2,y:-1,z:3);let bias=SIMD3<Double>(0.2,0.3,0.4)
        var preview=Orientation();preview.attitude=simd_quatd(angle:0.7,axis:SIMD3(0,1,0))
        sensor.applyCalibration(map:map,bias:bias,gravity:SIMD3(0,-1,0),preview:preview)
        sensor.recenter(flat:true)
        XCTAssertEqual(sensor.displayRotation.real,1,accuracy:0.000001)
        XCTAssertEqual(sensor.axes,map);XCTAssertEqual(sensor.gyroBias,bias)
        sensor.recenter(flat:false)
        XCTAssertEqual(sensor.displayRotation.real,cos(Double.pi/4),accuracy:0.000001)
    }
    func testTranslations() {
        XCTAssertFalse(Catalog.translations.isEmpty)
        for (key,row) in Catalog.translations {
            for language in ["pt-BR","es","zh-Hant"] { XCTAssertFalse((row[language] ?? "").isEmpty,key) }
        }
        XCTAssertEqual(Catalog.translate("Continue",language:"pt-BR"),"Continuar")
        XCTAssertEqual(Catalog.translate("Calibrate Victor",language:"es"),"Calibrar Victor")
        XCTAssertEqual(Catalog.translate("Continue",language:"zh-Hant"),"繼續")
    }
    func testAxes() {
        XCTAssertEqual(AxisMap(x:2,y:-1,z:3).apply(SIMD3(1,2,3)),SIMD3(2,-1,3))
        XCTAssertTrue(AxisMap(x:2,y:-1,z:3).valid)
        XCTAssertFalse(AxisMap(x:1,y:1,z:3).valid)
    }
    func testCRC() { XCTAssertEqual(DSU.crc(Array("123456789".utf8)),0xcbf43926) }
    func testRequest() { let b=[UInt8](DSU.packet(type:0x100002,payload:[1,0,0,0,0,0,0,0],id:7)); XCTAssertEqual(b.count,28);XCTAssertEqual(DSU.number(b,6,2),12) }
    func testSample() { let s=DSU.decode(fixture());XCTAssertNotNil(s);XCTAssertEqual(s?.gyro.x,90);XCTAssertEqual(s?.timestamp,1_000_000) }
    func testInvalid() { var b=fixture();b[90]^=1;XCTAssertNil(DSU.decode(b));XCTAssertNil(DSU.decode(Data(repeating:0,count:99))) }
    func testTare() { var o=Orientation(); var s=DSU.decode(fixture())!;o.update(s);s.timestamp+=100_000;o.update(s);XCTAssertGreaterThan(o.displayed.angle,0.1);o.tare();XCTAssertEqual(o.displayed.real,1,accuracy:0.000001) }
}
