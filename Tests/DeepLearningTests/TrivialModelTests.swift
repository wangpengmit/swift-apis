// Copyright 2018 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import DeepLearning

final class TrivialModelTests: XCTestCase {
    func testXOR() {
        struct Classifier: Layer {
            static var generator = PhiloxRandomNumberGenerator(uint64Seed: 51243124)
            var l1, l2: Dense<Float>
            init(hiddenSize: Int) {
                l1 = Dense<Float>(
                    inputSize: 2,
                    outputSize: hiddenSize,
                    generator: &Classifier.generator,
                    activation: relu
                )
                l2 = Dense<Float>(
                    inputSize: hiddenSize,
                    outputSize: 1,
                    generator: &Classifier.generator,
                    activation: relu
                )
            }
            @differentiable(wrt: (self, input))
            func applied(to input: Tensor<Float>) -> Tensor<Float> {
                let h1 = l1.applied(to: input)
                return l2.applied(to: h1)
            }
        }
        let optimizer = SGD<Classifier, Float>(learningRate: 0.02)
        var classifier = Classifier(hiddenSize: 4)
        let x: Tensor<Float> = [[0, 0], [0, 1], [1, 0], [1, 1]]
        let y: Tensor<Float> = [[0], [1], [1], [0]]

        let context = Context(learningPhase: .training)
        for _ in 0..<1000 {
            let (_, 𝛁model) = classifier.valueWithGradient { classifier -> Tensor<Float> in
                let ŷ = classifier.applied(to: x, in: context)
                return meanSquaredError(predicted: ŷ, expected: y)
            }
            optimizer.update(&classifier.allDifferentiableVariables, along: 𝛁model)
        }

        let ŷ = classifier.applied(to: x)
        XCTAssertEqual(round(ŷ), y)
    }

    static var allTests = [
        ("testXOR", testXOR),
    ]
}
