//
//  ViewController.swift
//  ASScrollTest
//
//  Created by David Taylor on 1/30/17.
//  Copyright © 2017 David Taylor. All rights reserved.
//

import UIKit
import AsyncDisplayKit

func makeABunchOfNodes() -> [ASLayoutElement] {
    return [
        FlagNode(descr: "red", color: UIColor.red, height: 80),
        FlagNode(descr: "yellow", color: UIColor.yellow, height: 40),
        FlagNode(descr: "blue", color: UIColor.blue, height: 120),
        FlagNode(descr: "green", color: UIColor.green, height: 300),
        FlagNode(descr: "orange", color: UIColor.orange, height: 10),
        FlagNode(descr: "black", color: UIColor.black, height: 160),
        FlagNode(descr: "cyan", color: UIColor.cyan, height: 100),
    ]
}

func configureScrollNode(_ scrollNode: ASScrollNode, automaticallyManagesContentSize: Bool) {
    scrollNode.automaticallyManagesSubnodes = true
    scrollNode.automaticallyManagesContentSize = automaticallyManagesContentSize
    scrollNode.backgroundColor = UIColor.lightGray
    scrollNode.style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
}



class FlagNode: ASDisplayNode {
    let descr: String
    let height: CGFloat

    init(descr: String, color: UIColor, height: CGFloat) {
        self.descr = descr
        self.height = height
        super.init()
        backgroundColor = color
        style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
    }

    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: height)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("tapped " + descr)
    }
}



class ContentNode: ASDisplayNode {
    let verticalNodes: [ASLayoutElement]

    override init() {
        verticalNodes = makeABunchOfNodes()
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = UIColor.white
        style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
        // style.height = ASDimensionMake(ASDimensionUnit.points, CGFloat.greatestFiniteMagnitude)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.children = verticalNodes
        return verticalStack
    }

    func calculatePreferredLayoutSize(constrainedSize: ASSizeRange) -> CGSize {
        let verticalLayouts = layoutThatFits(constrainedSize).sublayouts
        let maxLayoutSize = { (maxSize: CGSize, layout: ASLayout) -> CGSize in
            let maxWidth = max(maxSize.width, layout.frame.maxX)
            let maxHeight = max(maxSize.height, layout.frame.maxY)
            return CGSize(width: maxWidth, height: maxHeight)
        }
        return verticalLayouts.reduce(constrainedSize.max, maxLayoutSize)
    }

    func forceStyleSize(size: CGSize) {
        style.width = ASDimensionMake(size.width)
        style.height = ASDimensionMake(size.height)
        style.minSize = size
        style.maxSize = size
        style.preferredSize = size
    }
}



class ContentScrollNode: ASScrollNode {
    let verticalNodes: [ASLayoutElement]

    override init() {
        verticalNodes = makeABunchOfNodes()
        super.init()
        configureScrollNode(self, automaticallyManagesContentSize: true)
    }

    // FIXME: initialiser chain is broken so we get initialized twice
    // we have to implement this or we'll crash
    override init(viewBlock: @escaping ASDisplayNodeViewBlock, didLoad didLoadBlock: ASDisplayNodeDidLoadBlock? = nil) {
        verticalNodes = makeABunchOfNodes()
        super.init(viewBlock: viewBlock, didLoad: didLoadBlock)
        configureScrollNode(self, automaticallyManagesContentSize: true)
    }

    // Does not work
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.children = verticalNodes
        return verticalStack
    }
}



class ViewController: ASViewController<ASScrollNode> {
    var autoContentSize = true
    let contentNode: ContentNode

    required init?(coder aDecoder: NSCoder) {
        let contentNode = ContentNode()
        self.contentNode = contentNode

        /** UNCOMMENT ONLY ONE OF THESE EXPERIMENTS **/

        // EXPERIMENT 1: ASScrollNode subclassed directly that has an ASStackLayoutSpec:
        // Does not work
        let scrollNode = ContentScrollNode()

        // EXPERIMENT 2: ASScrollNode using layoutSpecBlock instead of subclassing to return an ASStackLayoutSpec:
        // Does not work
        // let scrollNode = ViewController.scrollNodeWithVerticalLayout(automaticallyManagesContentSize: autoContentSize)

        // EXPERIMENT 3: ASScrollNode wrapping an ASDisplayNode that has an ASStackLayoutSpec wrapped in a ASWrapperLayoutSpec:
        // Does not work
        // let scrollNode = ViewController.scrollNodeWrappingContentNode(contentNode, automaticallyManagesContentSize: autoContentSize)

        // EXPERIMENT 4: ASScrollNode wrapping an ASDisplayNode that has an ASStackLayoutSpec wrapped in a ASWrapperLayoutSpec and has the node's style dimensions set to the exact desired content size:
        // Does not work when using automaticallyManagesContentSize = true
        // Set autoContentSize to false to get this to work using the manual layout contentSize hacks
        // autoContentSize = false
        // let scrollNode = ViewController.scrollNodeWrappingContentNodeWithForcedLayout(contentNode, automaticallyManagesContentSize: autoContentSize)

        super.init(node: scrollNode)
    }

    // Attempt to provide an unbounded height for the layout calculations
    // Note that this doen't help - it gets trumped by the bounds during the viewWillAppear layout pass
    override func nodeConstrainedSize() -> ASSizeRange {
        if autoContentSize {
            let width: CGFloat = isViewLoaded ? view.bounds.width : 320
            let size = CGSize(width: width, height: 100000) // crashes if you use CGFloat.greatestFiniteMagnitude!!
            return ASSizeRangeMake(size)
        } else {
            return super.nodeConstrainedSize()
        }
    }

    static func scrollNodeWithVerticalLayout(automaticallyManagesContentSize: Bool) -> ASScrollNode {
        let scrollNode = ASScrollNode()
        let verticalNodes = makeABunchOfNodes()
        configureScrollNode(scrollNode, automaticallyManagesContentSize: automaticallyManagesContentSize)
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
            let verticalStack = ASStackLayoutSpec.vertical()
            verticalStack.children = verticalNodes
            return verticalStack
        }
        return scrollNode
    }

    static func scrollNodeWrappingContentNode(_ contentNode: ContentNode, automaticallyManagesContentSize: Bool) -> ASScrollNode {
        let scrollNode = ASScrollNode()
        configureScrollNode(scrollNode, automaticallyManagesContentSize: automaticallyManagesContentSize)
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
            return ASWrapperLayoutSpec(layoutElement: contentNode)
        }
        return scrollNode
    }

    static func scrollNodeWrappingContentNodeWithForcedLayout(_ contentNode: ContentNode, automaticallyManagesContentSize: Bool) -> ASScrollNode {
        let scrollNode = ASScrollNode()
        configureScrollNode(scrollNode, automaticallyManagesContentSize: automaticallyManagesContentSize)
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
            let contentSize = contentNode.calculatePreferredLayoutSize(constrainedSize: constrainedSize)
            contentNode.forceStyleSize(size: contentSize)
            contentNode.style.layoutPosition = CGPoint(x: 0, y: 0)
            return ASWrapperLayoutSpec(layoutElement: contentNode)
        }
        return scrollNode
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !autoContentSize {
            let newContentSize = contentNode.style.preferredSize
            if newContentSize != .zero && newContentSize != node.view.contentSize {
                node.view.contentSize = newContentSize
            }
        }
    }
}
