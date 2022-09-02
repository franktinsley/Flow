import NodeEditor
import SwiftUI

func simplePatch() -> Patch {

    let generator = Node(name: "generator",
                         position: CGPoint(x: 100, y: 100),
                         outputs: ["out"])

    let processor = Node(name: "processor",
                         position: CGPoint(x: 400, y: 100),
                         inputs: ["in"],
                         outputs: ["out"])

    let mixer = Node(name: "mixer",
                     position: CGPoint(x: 700, y: 100),
                     inputs: ["in1", "in2"],
                     outputs: ["out"])

    let output = Node(name: "output",
                      position: CGPoint(x: 1000, y: 100),
                      inputs: ["in"])

    let nodes = [generator, processor,
                 generator.translate(by: CGSize(width: 0, height: 100)),
                 processor.translate(by: CGSize(width: 0, height: 100)),
                 mixer,
                 output]

    let wires = Set([Wire(from: OutputID(0, 0), to: InputID(1, 0)),
                     Wire(from: OutputID(1, 0), to: InputID(4, 0)),
                     Wire(from: OutputID(2, 0), to: InputID(3, 0)),
                     Wire(from: OutputID(3, 0), to: InputID(4, 1)),
                     Wire(from: OutputID(4, 0), to: InputID(5, 0))])

    return Patch(nodes: nodes, wires: wires)

}

/// Bit of a stress test to show how NodeEditor performs with more nodes.
func randomPatch() -> Patch {

    var randomNodes: [Node] = []
    for n in 0 ..< 50 {
        let randomPoint = CGPoint(x: 1000 * Double.random(in: 0...1),
                                  y: 1000 * Double.random(in: 0...1))
        randomNodes.append(Node(name: "node\(n)",
                                position: randomPoint,
                                inputs: ["In"],
                                outputs: ["Out"]))
    }

    var randomWires: Set<Wire> = []
    for n in 0 ..< 50 {
        randomWires.insert(Wire(from: OutputID(n, 0), to: InputID(Int.random(in: 0...49), 0)))
    }
    return Patch(nodes: randomNodes, wires: randomWires)
}

struct ContentView: View {
    @State var patch = simplePatch()
    @State var selection = Set<NodeIndex>()

    var body: some View {
        PatchView(patch: $patch, selection: $selection)
    }
}
