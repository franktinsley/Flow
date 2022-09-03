// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Flow/

import SwiftUI

extension NodeEditor {
    /// State for all gestures.
    enum DragInfo {
        case wire(output: OutputID, offset: CGSize = .zero, hideWire: Wire? = nil)
        case node(index: NodeIndex, offset: CGSize = .zero)
        case selection(rect: CGRect = .zero)
        case none
    }

    /// Adds a new wire to the patch, ensuring that multiple wires aren't connected to an input.
    func connect(_ output: OutputID, to input: InputID) {
        let wire = Wire(from: output, to: input)

        // Remove any other wires connected to the input.
        patch.wires = patch.wires.filter { w in
            let result = w.input != wire.input
            if !result {
                wireRemoved(w)
            }
            return result
        }
        patch.wires.insert(wire)
        wireAdded(wire)
    }

    func attachedWire(inputID: InputID) -> Wire? {
        patch.wires.first(where: { $0.input == inputID })
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragInfo) { drag, dragInfo, _ in

                switch patch.hitTest(point: drag.startLocation, layout: layout) {
                case .background:
                    dragInfo = .selection(rect: CGRect(a: drag.startLocation,
                                                       b: drag.location))
                case let .node(nodeIndex):
                    dragInfo = .node(index: nodeIndex, offset: drag.translation)
                case let .output(nodeIndex, portIndex):
                    dragInfo = DragInfo.wire(output: OutputID(nodeIndex, portIndex), offset: drag.translation)
                case let .input(nodeIndex, portIndex):
                    let node = patch.nodes[nodeIndex]
                    // Is a wire attached to the input?
                    if let attachedWire = attachedWire(inputID: InputID(nodeIndex, portIndex)) {
                        let offset = node.inputRect(input: portIndex, layout: layout).center
                            - patch.nodes[attachedWire.output.nodeIndex].outputRect(
                                output: attachedWire.output.portIndex,
                                layout: layout
                            ).center
                            + drag.translation
                        dragInfo = .wire(output: attachedWire.output,
                                         offset: offset,
                                         hideWire: attachedWire)
                    }
                }
            }
            .onEnded { drag in

                switch patch.hitTest(point: drag.startLocation, layout: layout) {
                case .background:
                    selection = Set<NodeIndex>()
                    let selectionRect = CGRect(a: drag.startLocation,
                                               b: drag.location)
                    for (idx, node) in patch.nodes.enumerated() {
                        if selectionRect.intersects(node.rect(layout: layout)) {
                            selection.insert(idx)
                        }
                    }
                case let .node(nodeIndex):
                    patch.nodes[nodeIndex].position += drag.translation
                    self.nodeMoved(nodeIndex, patch.nodes[nodeIndex].position)
                    if selection.contains(nodeIndex) {
                        for idx in selection where idx != nodeIndex {
                            patch.nodes[idx].position += drag.translation
                            self.nodeMoved(idx, patch.nodes[idx].position)
                        }
                    }
                case let .output(nodeIndex, portIndex):
                    if let input = findInput(point: drag.location) {
                        connect(OutputID(nodeIndex, portIndex), to: input)
                    }
                case let .input(nodeIndex, portIndex):
                    // Is a wire attached to the input?
                    if let attachedWire = attachedWire(inputID: InputID(nodeIndex, portIndex)) {
                        patch.wires.remove(attachedWire)
                        wireRemoved(attachedWire)
                        if let input = findInput(point: drag.location) {
                            connect(attachedWire.output, to: input)
                        }
                    }
                }
            }
    }
}