//
//  UICollectionView+UpdateRows.swift
//  Computopias
//
//  Created by Nate Parrott on 3/31/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UICollectionView {
    func updateRows(newRows: [CardFeedViewController.RowModel], oldRows: [CardFeedViewController.RowModel]) {
        
    }
}

struct Diff {
    static func test() {
        let pairs: [([Float], [Float])] = [
            ([1,2,3], [1,2,3]),
            ([1,2,3], [1,2,3,4]),
            ([1,2,3], [1,2]),
            ([1,2,3], [1,2,2.5,3]),
            ([1,2,3], [0,1,2,3])
        ]
        
        for (old, new) in pairs {
            print("old: \(old)")
            print("new: \(new)")
            let d = Compute(new, oldSeq: old)
            print("diff: \(d)")
        }
    }
    
    enum Action: CustomStringConvertible {
        case Delete([Int])
        case Insert([Int])
        case Reload([Int])
        
        var description: String {
            get {
                switch self {
                case .Delete(let indices): return "Delete(\(indices))"
                case .Insert(let indices): return "Insert(\(indices))"
                case .Reload(let indices): return "Reload(\(indices))"
                }
            }
        }
    }
    static func OrderActionsDeletionsFirst(actions: [Action]) -> [Action] {
        var deletionsYet = 0
        var deletions = [Action]()
        var nonDeletions = [Action]()
        for action in actions {
            switch action {
            case .Delete(let indices):
                deletionsYet += indices.count
                deletions.append(action)
            case .Insert(let indices):
                nonDeletions.append(.Insert(indices.map({ $0 - deletionsYet })))
            case .Reload(let indices):
                nonDeletions.append(.Reload(indices.map({ $0 - deletionsYet })))
            }
        }
        return deletions + nonDeletions
    }
    static func Compute<T:Equatable>(newSeq: [T], oldSeq: [T]) -> [Action] {
        return _Compute(newSeq, oldSeq: oldSeq, oldSeqIdx: 0, newSeqIdx: 0)
    }
    static func _Compute<T:Equatable>(newSeq: [T], oldSeq: [T], oldSeqIdx: Int, newSeqIdx: Int) -> [Action] {
        if newSeq.count == 0 && oldSeq.count > 0 {
            return [Action.Delete(Array(oldSeqIdx..<(oldSeqIdx + oldSeq.count)))]
        } else if newSeq.count > 0 && oldSeq.count == 0 {
            return [Action.Insert(Array(oldSeqIdx..<(oldSeqIdx + newSeq.count)))]
        } else if newSeq.count > 0 && oldSeq.count > 0 {
            let subseq = _rangeOfLongestMatchingSubsequence(newSeq, oldSeq: oldSeq)
            if subseq.seqLen == 0 {
                let lengthOfReplacement = min(newSeq.count, oldSeq.count)
                let ns: [T] = Array(newSeq[lengthOfReplacement..<newSeq.count])
                let os: [T] = Array(oldSeq[lengthOfReplacement..<oldSeq.count])
                return [Action.Reload(Array(oldSeqIdx..<(oldSeqIdx+lengthOfReplacement)))] + _Compute(ns, oldSeq: os, oldSeqIdx: oldSeqIdx + lengthOfReplacement, newSeqIdx: newSeqIdx + lengthOfReplacement)
            } else {
                let ns1 = Array(newSeq[0..<subseq.newSeqStart])
                let os1 = Array(oldSeq[0..<subseq.oldSeqStart])
                let ns2 = Array(newSeq[subseq.newSeqStart + subseq.seqLen..<newSeq.count])
                let os2 = Array(oldSeq[subseq.oldSeqStart + subseq.seqLen..<oldSeq.count])
                return _Compute(ns1, oldSeq: os1, oldSeqIdx: oldSeqIdx, newSeqIdx: newSeqIdx) + _Compute(ns2, oldSeq: os2, oldSeqIdx: oldSeqIdx + subseq.oldSeqStart + subseq.seqLen, newSeqIdx: newSeqIdx + subseq.newSeqStart + subseq.seqLen)
            }
        } else {
            return []
        }
    }
    static func _rangeOfLongestMatchingSubsequence<T:Equatable>(newSeq: [T], oldSeq: [T]) -> (newSeqStart: Int, oldSeqStart: Int, seqLen: Int) {
        var bestSeqNewStart = 0
        var bestSeqOldStart = 0
        var bestSeqLen: Int = 0
        for oldIdx in 0..<oldSeq.count {
            for newIdx in 0..<newSeq.count {
                var l = 0
                while newIdx + l < newSeq.count && oldIdx + l < oldSeq.count && newSeq[newIdx + l] == oldSeq[oldIdx + l] {
                    l += 1
                    if l > bestSeqLen {
                        bestSeqLen = l
                        bestSeqNewStart = newIdx
                        bestSeqOldStart = oldIdx
                    }
                }
            }
        }
        return (newSeqStart: bestSeqNewStart, oldSeqStart: bestSeqOldStart, seqLen: bestSeqLen)
    }
}
