//
//  model.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import Foundation


class Model: ObservableObject {
    
    // Dictionaries for map from alphabet to integer and back
    let a_to_n = ["a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7, "i": 8, "j": 9, "k": 10, "l": 11, "m": 12, "n": 13, "o": 14, "p": 15, "q": 16, "r": 17, "s": 18, "t": 19, "u": 20, "v": 21, "w": 22, "x": 23, "y": 24, "z": 25, " ": 26]
    let n_to_a = [0: "a", 1: "b", 2: "c", 3: "d", 4: "e", 5: "f", 6: "g", 7: "h", 8: "i", 9: "j", 10: "k", 11: "l", 12: "m", 13: "n", 14: "o", 15: "p", 16: "q", 17: "r", 18: "s", 19: "t", 20: "u", 21: "v", 22: "w", 23: "x", 24: "y", 25: "z", 26: " "]
    
    @Published var code: [Int] = [] // codebook for the conversation
    @Published var enc_p: Int = 0 // encoding codebook pointer
    @Published var dec_p: Int = 0 // decoding codebook pointer
    @Published var error = false // error indicator
    @Published var ciphertexts: [String] = []
    
    func generate (n: Int) {
        for _ in 0..<n {
            code.append(Int.random(in: 0...26))
        }
    }
    
    func enc (plain: String){
        
        var cipher = ""
        
        if plain.count > code.count - enc_p {
            error = true
            return
        } else {
            error = false
        }
        
        for i in plain {
            let c = String(i)
            let n = ((a_to_n[c] ?? 26) + code[enc_p]) % 27
            cipher += n_to_a[n] ?? " "
            enc_p += 1
        }
        
        ciphertexts.append(cipher)
    }
    
    func dec () -> String {
        
        var plaintext = ""

        let cipher = ciphertexts[0]
        
        for i in cipher {
            let c = String(i)
            let n = ((a_to_n[c] ?? 26) - code[dec_p] + 27) % 27
            plaintext += n_to_a[n] ?? " "
            dec_p += 1
        }
        
        ciphertexts.removeFirst()
        
        return plaintext
    }
}
