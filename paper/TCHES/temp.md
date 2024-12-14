The extensive duration primarily arises from the vast number of operations involved in MSM. Each point-scalar multiplication requires thousands of big integer modular multiplications. An MSM comprises millions to billions of point-scalar multiplications, and generating a proof demands several MSMs.


The latency includes the data transfer time between the host and FPGAs and the running time of both FPGAs and host. As mentioned in Section 4, an MSM task is split into smaller sub-tasks which are sent to available PEs on FPGAs. The results of PEs are collected and processed by the host to obtain the final result.


As one of the most powerful cryptographic tools, ZKP has the potential to be used in many privacy-preserving applications, such as contingent payment [3], verifying convolutional neural networks [2], approval voting [4] and group signature construction [5].


ZKP has been studied by researchers all over the world for decades in order to guarantee a seat in the practical field. Hard works are paid off, in recent years, cryptographic proofs with strong privacy and efficiency properties, known as ZeroKnowledge Succinct Non-interactive ARgument of Knowledge (zk-SNARK)[10] have garnered considerable interest in academic circle and have been implemented in various industrial settings. As a subtype of ZKP, zk-SNARK process involves key generation, proof generation and proof verification. The key generation process creates a proving key (pk) and a verification key (vk) pair using a secret key, which is then discarded for security purposes. The prover comprises equations of the proof, and the proof is a non-interactive proof of knowledge that is succinct. The proof is usually very concise and can be verified effortless. The proof verification is a stage for verifying the proof, which can be repeated any number of times, and each time may have different inputs. The vk, the proof and the public inputs are given to the verifier for correctness checking.



Among many obstacles in the proof generation, an indispensable step is efficiently evaluating polynomials at points requested by the verifier. And most of the popular protocols have strong presence of Multi-Scalar Multiplication (MSM) operation in polynomial commitments as shown in Fig. 2. which involve extensive point additions and doublings on elliptic curves. This can stimulate sufficient motivation to treat MSM as a standalone problem, even from a theoretical perspective, it turns out to be a pivotal problem that needs to be tackled for purpose of accelerating ZK-SNARK protocol.


Each sipi pair is a point scalar multiplication and MSM needs to add up these products to get one final point. Most zkSNARK protocols need several times of MSM with different scalar vectors at different stage when committing a polynomial into a commitment point during the proof generation process [13]. The point vectors are known ahead of time as fixed parameters for a certain application problem, as long as the application field remains stable, the point set stays unchanged. On the contrary, the scalar values representing the polynomial coefficients vary with different witnesses.
The elliptic curve point set that we use in our experiment are called SRS. It is an abbreviation of Structured Reference String: A common reference string created by sampling from some complex distribution, often involving a sampling algorithm with internal randomness that must not be revealed, since it would create a trapdoor that enables creation of convincing proofs for false statements. The SRS may be non-universal or universal. The SRS points mentioned in the design are considered to be unchanged during the execution of MSM.

This has led to efforts in offloading the compute-intensive operations, such as Multi-scalar Multiplication (MSM) and Number Theoretic Transform (NTT), to accelerators like GPUs and FPGAs.

This work aims to address the acceleration of the MSM operation for widely adopted elliptic curves like BN128 and BLS12-381.

With its widespread adoption in applications such as blockchain and verifiable machine learning, the demand for generating zero-knowledge proofs has increased dramatically.

Third, we adopt a dynamic loading method for the data required for proof generation, reducing the required device memory.
multi-stream technology enables the overlap of data transfers and GPU computations, reducing overhead caused by data exchanges between host and device memory.

With the growing deployment of ZKP, the demand for generating zero-knowledge proofs has increased dramatically. A report from Protocol Labs [32] states that the demand is expected to reach a staggering nearly 90 billion zero-knowledge proofs from the time ZKPs start to be applied in real-world applications to 2030. Moreover, generating zero-knowledge proofs is a compute-intensive task. For example, ZENO [13], a start-of-the-art ZKP scheme for verifiable neural networks, requires more than 40 seconds to generate a single proof for the prediction of the VGG-16 model [52] with a CIFAR-10 image [8] as input. Therefore, improving the efficiency of proof generation has become one of the most important topics in expanding the deployment of ZKP in practical applications.

On the other hand, at the practical level, GPU is a powerful tool to further improve computational efficiency through tens of thousands of execution cores operating in parallel. Considerable efforts [7, 29, 36, 38] have been directed toward developing GPU-accelerated systems for proof generation.


However, these previous GPU-accelerated systems [7, 29, 36, 38] only explored how to efficiently generate a single proof, with the goal of reducing proof generation latency. These systems spend over-abundant GPU resources on individual proof generation, failing to optimize the overall throughput of batch generation. Improving throughput is critical in the industry as it means more proofs to be generated per unit of time, resulting in greater economic benefits. In addition, these systems only cover ZKP protocols [3, 15, 22] that rely on expensive computational modules

Multi-Scalar Multiplication (MSM) is a computationally intensive step in zk-SNARK proof generation and has become a focus for industry acceleration efforts.


Unfortunately, while the verification of zk-SNARK proofs is fast, the generation of these proofs at the prover side imposes significant computation overhead and time requirements, which poses a significant challenge to the practical applications of zk-SNARK.


Among these steps, MSM consumes the most computation overhead and time, making it a major focus for industry acceleration efforts.


There are three main approaches to accelerate MSM in zkSNARK: GPUs, ASICs, and FPGAs. GPUs are commonly used but may struggle with efficient handling of arithmetic operations over large finite fields. They also come with high costs, especially in terms of power consumption. ASICs offer better power efficiency and performance for MSM, but the adoption of different elliptic curves presents a challenge. Creating dedicated ASICs for each curve becomes impractical. On the other hand, FPGAs provide flexibility for MSM acceleration. They can implement custom circuits for arithmetic operations and can be programmed to switch between different circuits for various curves. This flexibility improves the practicality and versatility of MSM accelerators in zk-SNARK applications.


However, most of these existing works simplify the control logic by sequentially accumulating each element of a barrel during the Barrel Accumulation step. This approach introduces two performance issues: barrel collisions and the inability to utilize the associative law of addition.


ZKP has gained widespread application due to its strong privacy features in various fields. It has been successfully used in electronic voting [2], verifiable database outsourcing [3], verifiable machine learning [4] and verifiable outsourcing [13]. Among ZKP algorithms, zk-SNARK is a practical choice, with successful deployments in real-world systems like ZCash [14]and Pinocchio coin [15]. These systems require confidential transactions while maintaining the ability to prove transaction validity. zk-SNARK provides this dual functionality, ensuring privacy and verifiability in such applications.

To enhance the performance of zk-SNARK proofs generation, prior works have focused on implementing highperformance accelerators using GPUs, ASICs, and FPGAs. These accelerators offer efficient solutions for different hardware platforms. PipeZK [6] is an ASIC-based zk-SNARK hardware accelerator supports multiple curves. It utilizes a 4-step algorithm and the Pippenger algorithm in its POLY and MSM accelerator, achieving outstanding performance.  PipeMSM [7] is a FPGA-based MSM hardware accelerator which introduces innovative PADD design ideas and a high-performance parallel algorithm for Barrel Aggregation. CycloneMSM [8] and CycloneNTT [16] are FPGA-based MSM and POLY accelerators, developed by the same team. CycloneMSM convert the PADD operations from BLS12-377 to the Twisted Edwards curve, utilizing fewer modular multipliers. HARDCAML [9] is also a FPGA-based MSM hardware accelerator which won the 2022 ZPrize [17] championship. It has the best performance among all published FPGAbased MSM accelerators to date. CuZK [18] and GZKP [12] are high-performance GPU-based MSM acceleration works. CuZK supports parallel execution on multiple GPUs, while GZKP focuses on single-GPU performance.

The operations supported by points on an elliptic curve include point addition (PADD), point doubling (PDBL), and point scalar multiplication (PMULT). Similar to using shifting and addition for multiplication, PMULT can also be performed by a series of PADD and PDBL operations. PADD and PDBL involve arithmetic operations over large finite fields, and efficient algorithms for these operations often utilize projection coordinates (X : Y : Z), where x = X  Z and y = Y  Z , to avoid  modular inverse calculations [19].

Non-unified addition refers to an algorithm that supports adding only different points, while unified addition allows the addition of any two points.

Clearly, MSM is computationally intensive, requiring approximately N times of PMULT operations, which is roughly equivalent to 1.5 × W × N timses of PADD operations.


The Pippenger algorithm, which trades storage space for lower computation overhead, consists of three steps, as illustrated in Figure 3.

Among the three steps of the Pippenger algorithm, the Barrel Accumulation step consumes the largest proportion of the computation overhead. In fact, when s is 13 and N exceeds 220, the Barrel Accumulation step accounts for more than 99% of the total computation overhead of the Pippenger algorithm.

Implementing the MSM requires two elliptic curve operations: point addition and point doubling. These operations can be optimized with efficient modulo reduction algorithms such as Barrett [3] or Montgomery, and better-than-O (n2) multiplication techniques such as the Karatsuba [13] algorithm. A naive algorithm using repeated point addition of scalar-point sums can compute MSMs with a few thousand inputs. When the scale of a MSM increases into the range of more than a million points, other algorithms such as Pippengers [20] provide much better performance. Pippengers is discussed in more detail in the architecture section. Figure 1 shows how the MSM problem relies on optimized EC primitives, and feeds into the overall ZKP algorithm.

We target the BLS12-377 curve, which is popular in many ZKP systems due to its high security level, and which can be transformed into other coordinate systems that allow for faster hardware implementations. In BLS12-377 λ is 377 bits and δ is 253 bits.

We target the BLS12-377 curve, which is popular in many ZKP systems due to its high security level, and which can be transformed into other coordinate systems that allow for faster hardware implementations. In BLS12-377 λ is 377 bits and δ is 253 bits.

For example, on the BLS12377 curve with N = 226 and W = 16, the bucket sums require over 1 billion point additions, while the rest of the computation requires only about 8,000 operations.

Because the base points p do not change over multiple rounds of a a given ZKP, we can precompute curve and coordinate transformations on p and store them in DDR memory on the FPGA board. We then need to send only the scalars s to the FPGA to compute the MSM.

In order to pick values of bucket size B and number of slices W , we take into account the amount of memory used on the FPGA and the amount of time required to compute the triangle sums and final accumulations on the CPU.

Previous work [1] reduced the number of bucket sums required by using a small number of large slices (B = 16). However, all the buckets for a slice of this size cannot fit in the FPGA’s URAM. Values of pisi [slicew] are not pre-sorted, as  the scalars contain random values picked at runtime.

In order to optimize these we use the Karatsuba algorithm, which requires O (nlog23) ≈ O (n1.585) single-digit multiplications to multiply an n digit number, rather than the naive long-multiplication algorithm, which requires O (n2) single digit multiplications.


In the context of zk-SNARK, MSM emerges as a major computational bottleneck, particularly due to its high computational and memory overhead.

As a result, directing efforts towards utilizing hardware for the general acceleration of the MSM task in zk-SNARK is becoming a crucial research focus in contemporary cryptography and computing domains.

Recent research in this field has primarily concentrated on optimizing single-device performance or introducing new protocols based on distributed systems. However, these approaches exhibit certain limitations in real-world applications and face challenges in achieving universal scalability.

Resources of a single machine are typically limited, which potentially severely constraining the practical applicability.

In other words, the search for the optimal window size becomes crucial when constrained by a fixed number of threads and MSM scale.

CPU-GPU heterogeneous architecture [30,31] is a computing architecture that uses CPU and GPU to work together, CPU and GPU have their own storage space, and data transmission is carried out through PCI-e bus [32].This architecture allows the CPU and GPU to play their respective advantages in processing different types of tasks, thus improving the performance of the overall system [33].As a programming framework for parallel computing in heterogeneous computing environments, CUDA [34,35] is based on NVIDIA’s GPU architecture [36] and provides programming interfaces and toolsets specifically for parallel computing on GPU [37]. Its heterogeneous architecture is shown in Fig. 8.

CUDA stream [38,39], serving as a parallel computing model, is a mechanism to achieve asynchronous operations between the host and device. Using the asynchronous mechanism of CUDA stream, the point set can be transferred from the host side to the device side while the GPU executes the scalar form transformation kernel.

Finally, to ensure that our approach can be compared with the most advanced solutions in the real-world applications, the data scale in our  experiments is higher than223