//
//  GameScene.swift
//  SortBot
//
//  Created by David Roth on 7/2/16.
//  Copyright © 2016 David Roth. All rights reserved.
//

import SpriteKit
import GameplayKit

// Node name constants
private let kBlackNodeName = "BlackRubbishItem"
private let kBlueNodeName = "BlueRubbishItem"
private let kGreenNodeName = "GreenRubbishItem"

private let kGarbageBinName = "garbage bin"
private let kRecycleBinName = "recycling bin"
private let kCompostBinName = "compost bin"
private let kLearnedBinName = "learned bin"

private var attributes : [NSObjectProtocol] = ["NodeColor" as NSObjectProtocol, "Foo" as NSObjectProtocol]
private var examples : [[NSObjectProtocol]] = []
private var actions  : [NSObjectProtocol] = []

// Physics constants
let rubbishItemMask : UInt32 = 0x1 << 0;  // 1
let binMask         : UInt32 = 0x1 << 1;  // 2

// Gameplay Kit Decision Tree
var gameMoves : [String:String]? = nil

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var selectedNode : SKSpriteNode?
    var rubbishItem : SKSpriteNode!
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
    }
    
    override func sceneDidLoad() {
        self.loadRubbishItem()
        let chyron = self.childNode(withName: kLearnedBinName) as! SKSpriteNode
        chyron.alpha = 0.5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let positionInScene = touch?.location(in: self)
        if let touchedItem = self.atPoint(positionInScene!) as? SKSpriteNode {
            if touchedItem.name == kBlackNodeName ||
                touchedItem.name == kBlueNodeName ||
                touchedItem.name == kGreenNodeName {
                selectedNode = touchedItem
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if (selectedNode != nil) {
            selectedNode?.position = (touch?.location(in: self))!
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.checkForDisposal()
    }
    
    //Game Functions
    
    func checkForDisposal() {
        guard let selectedNode = selectedNode,
              let name = selectedNode.name
            else { return }
        
        let binNode = findBinNamed(name)
        //let intersects = (selectedNode?.intersects(binNode))!
        let contained = binNode.frame.contains(selectedNode.frame)
        if contained {
            // make a note that we have placed item A in bin B
            self.logDisposal(rubbishItem: selectedNode, inBin: binNode)
            self.removeRubbishItem(item: selectedNode)
        } else {
            let chyron = self.childNode(withName: kLearnedBinName) as! SKSpriteNode
            if chyron.frame.contains((selectedNode.frame)) {
                // get a random target
                let targetBin = self.getLearnedBin()
                let chyron = self.childNode(withName: kLearnedBinName) as! SKSpriteNode
                let enable = examples.first(where: {  $0[0] as! String == kGreenNodeName }) != nil &&
                    examples.first(where: {  $0[0] as! String == kBlueNodeName }) != nil &&
                    examples.first(where: {  $0[0] as! String == kBlackNodeName }) != nil
                chyron.alpha = enable ? 1 : 0.5

                self.move(rubbishItem: selectedNode, toBin: targetBin)
            } else {
                self.returnRubbishItem(item: selectedNode)
            }
        }
        let chyron = self.childNode(withName: kLearnedBinName) as! SKSpriteNode
        let enable = examples.first(where: {  $0[0] as! String == kGreenNodeName }) != nil &&
            examples.first(where: {  $0[0] as! String == kBlueNodeName }) != nil &&
            examples.first(where: {  $0[0] as! String == kBlackNodeName }) != nil
        chyron.alpha = enable ? 1 : 0.5

    }
    
    func logDisposal(rubbishItem: SKSpriteNode, inBin: SKSpriteNode) {
        let rubbishItemName = rubbishItem.name!
        let binName = inBin.name
        examples.append([rubbishItemName as NSObjectProtocol, "Bar" as NSObjectProtocol])
        actions.append(binName! as NSObjectProtocol)
    }
    
    func returnRubbishItem(item: SKSpriteNode) {
        let returnAction = SKAction.move(to: CGPoint(x: 0.0, y: 0.0), duration: 0.75)
        returnAction.timingMode = .easeInEaseOut
        item.run(returnAction)
    }
    
    func removeRubbishItem(item: SKSpriteNode) {
        let removeAction = SKAction.scale(by: 0.1, duration: 0.5)
        item.run(removeAction) {
            item.removeFromParent()
            self.selectedNode = nil
            self.loadRubbishItem()
        }
    }
    
    func findBinNamed(_ name: String) -> SKSpriteNode {
        switch name {
            case kBlackNodeName:
                return childNode(withName: kGarbageBinName) as! SKSpriteNode
            case kBlueNodeName:
                return childNode(withName: kRecycleBinName) as! SKSpriteNode
            case kGreenNodeName:
                return childNode(withName: kCompostBinName) as! SKSpriteNode
            default:
                return SKSpriteNode()
        }
    }
    
    func loadRubbishItem() {
        // grab a random rubbish item from the RubbishItem scene
        let rubbishItems  = SKScene(fileNamed: "RubbishItem")!.children
        let randomSource = GKShuffledDistribution(forDieWithSideCount: 3)
        let index = randomSource.nextInt() - 1
        let rubbishItem = rubbishItems[index]
        rubbishItem.removeFromParent()
        self.addChild(rubbishItem)
        rubbishItem.physicsBody!.contactTestBitMask = binMask
        rubbishItem.position = CGPoint(x: 0,
                                       y: 0)
    }
    
    //Robot Controls
    func move(rubbishItem: SKSpriteNode?, toBin: SKSpriteNode?) {
        // simulate touch-and-drag of the rubbish item to the coordinates
        // of the target bin
        let targetPosition = toBin?.position
        let disposeAction = SKAction.move(to: targetPosition!, duration: 0.75)
        rubbishItem?.run(disposeAction, completion: {
            self.checkForDisposal()
        })
    }
    
    func getRandomBin() -> SKSpriteNode {
        // build a decision tree with three random actions:
        // move to recycle, move to compost, or move to trash
        // first question is bogus
        let baseQuestion = "Test?"
        let randomDecisionTree = GKDecisionTree(attribute: baseQuestion as NSObjectProtocol)
        let rootNode = randomDecisionTree.rootNode
        
        let trashAction = kGarbageBinName
        let recycleAction = kRecycleBinName
        let compostAction = kCompostBinName
        
        // if you forget this, it segfaults.
        // Random decision trees need a random source; it
        // won't load one for you by default.
        randomDecisionTree.randomSource = GKRandomSource()
        
        rootNode?.createBranch(weight: 3, attribute: trashAction as NSObjectProtocol)
        rootNode?.createBranch(weight: 3, attribute: recycleAction as NSObjectProtocol)
        rootNode?.createBranch(weight: 3, attribute: compostAction as NSObjectProtocol)
        
        let randomBin = randomDecisionTree.findAction(forAnswers: [:]) as! String
        
        return self.childNode(withName: randomBin) as! SKSpriteNode
    }
    
    func getLearnedBin() -> SKSpriteNode {
        guard
            examples.count > 0,
            let node = selectedNode,
            let name = node.name,
            examples.first(where: {  $0[0] as! String == kGreenNodeName }) != nil,
            examples.first(where: {  $0[0] as! String == kBlueNodeName }) != nil,
            examples.first(where: {  $0[0] as! String == kBlackNodeName }) != nil
            else { return SKSpriteNode() }
        
        let myDecisionTree = GKDecisionTree(examples: examples, actions: actions, attributes: attributes)
        print(myDecisionTree.description)
        let binName = myDecisionTree.findAction(forAnswers: ["NodeColor": name as NSObjectProtocol]) as? String
        return childNode(withName: binName!) as! SKSpriteNode
    }
}
