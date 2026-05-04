#include <opencv2/dnn.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <iostream>

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: yolo_smoke <model.onnx> [image]\n";
        return 1;
    }
    std::string modelPath = argv[1];
    std::string imagePath = (argc >= 3) ? argv[2] : "";

    try {
        cv::dnn::Net net = cv::dnn::readNetFromONNX(modelPath);
        if (net.empty()) {
            std::cerr << "Failed to load model: " << modelPath << "\n";
            return 2;
        }
        std::cout << "Model loaded OK" << std::endl;
        if (!imagePath.empty()) {
            cv::Mat img = cv::imread(imagePath);
            if (img.empty()) {
                std::cerr << "Failed to read image: " << imagePath << "\n";
                return 3;
            }
            cv::Mat blob = cv::dnn::blobFromImage(img, 1.0/255.0, cv::Size(640,640), cv::Scalar(0,0,0), true, false);
            net.setInput(blob);
            std::vector<cv::Mat> outputs;
            net.forward(outputs, net.getUnconnectedOutLayersNames());
            std::cout << "Outputs count: " << outputs.size() << "\n";
            for (size_t i=0;i<outputs.size();++i) {
                std::cout << "Output["<<i<<"] dims: ";
                for (int d=0; d<outputs[i].dims; ++d) std::cout << outputs[i].size[d] << " ";
                std::cout << " type=" << outputs[i].type() << "\n";
                // print first 10 floats
                float* data = (float*)outputs[i].data;
                int cnt = std::min<int>(10, static_cast<int>(outputs[i].total()));
                std::cout << "First " << cnt << " vals: ";
                for (int k = 0; k < cnt; ++k)
                    std::cout << data[k] << " ";
                std::cout << "\n";
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << "\n";
        return 4;
    }
    return 0;
}
