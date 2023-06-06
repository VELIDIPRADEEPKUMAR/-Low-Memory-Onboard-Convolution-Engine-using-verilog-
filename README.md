# <b> Low-Memory-Onboard-Convolution-Engine-using-verilog </b>

As part of my FPGA-based project, I developed a high-performance convolution accelerator that enables real-time image processing with minimal memory requirements. This project aimed to address the challenges of implementing computationally intensive convolution operations on resource-constrained devices, such as embedded systems and edge computing devices.

## <b>  Key Features: </b>

- <b>  Efficient Convolution: </b> The accelerator leverages optimized hardware architecture and parallel processing techniques to perform convolutions on incoming image data in real time.

- <b>  Low-Memory Footprint: </b> By strategically buffering only three rows of the image frame, the accelerator significantly reduces the memory footprint, making it ideal for memory-constrained environments.

- <b>  Seamless Integration:</b>  The implementation seamlessly integrates with an OV7670 camera module to directly process the incoming image data without the need for intermediate memory storage.

- <b>  Real-Time Performance: </b> The accelerator processes each pixel of the image frame in parallel, ensuring real-time performance even for high-resolution images.

- <b>  Versatility:</b>  The accelerator supports configurable kernel sizes and is easily adaptable to various convolution-based image processing applications, such as edge detection, object recognition, and more.

## <b>  Impact and Applications: </b>

- <b>  Surveillance Systems: </b> The project's low-memory convolution approach is particularly valuable for real-time video analytics and surveillance systems, where memory limitations and immediate processing are critical factors.

- <b>  Embedded Systems: </b> The accelerator can be integrated into embedded systems used in robotics, autonomous vehicles, and smart devices, enabling efficient and real-time image processing capabilities.

- <b>  Edge Computing: </b> By offloading the computation-intensive convolution tasks to dedicated hardware, the accelerator contributes to the efficiency and responsiveness of edge computing devices.
