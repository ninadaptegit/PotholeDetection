# Pothole Detection and Reporting System

This repository contains an end-to-end full-stack application designed to detect potholes in real-time using a mobile device's camera. The system consists of a back-end deep learning API and a cross-platform mobile application.

## Project Overview

The primary goal of this project was to build a complete, production-ready system that demonstrates knowledge in modern deep learning, back-end development, and mobile app development. 

The application allows a user to capture an image from their phone's camera or gallery, send it to a back-end API, and receive a response with the location of any detected potholes. The results are then laid on the original image for a clear visual representation.

## Technology Stack

* **Mobile App (Front-end):**
    * **Flutter (Dart):** For building a single, cross-platform mobile application for both Android.
    * **Dart:** The programming language used for the Flutter app.

* **API (Back-end):**
    * **Python:** The core programming language for the back-end logic.
    * **FastAPI:** A modern, high-performance web framework for building the API.
    * **PyTorch:** The deep learning framework used to fine-tune and run the YOLOv11 model.

* **Infrastructure:**
    * **Docker:** Used to containerize the back-end API, ensuring a consistent and reproducible environment for deployment.

## Key Features

1.  **Pothole Detection:** Utilizes a custom-trained YOLOv11 model to accurately identify and localize potholes in images.
2.  **End-to-End Functionality:** Demonstrates a complete workflow from image capture on a mobile device to processing on a local server and displaying the results back to the user.
4.  **Robust API:** A high-performance, containerized RESTful API that handles image uploads and returns structured JSON data.
5.  **Portable Architecture:** The use of Docker ensures the back-end service can be run consistently on any environment, from a local machine to a cloud platform (not integrated).

## Project Structure and Setup

### Back-end API

The back-end is a Python-based FastAPI application.

1.  **Clone the repository:**
    `git clone`

2.  **Build the Docker image:**
    `docker build -t pothole-detector-api .`

3.  **Run the container:**
    `docker run -p 8000:8000 pothole-detector-api`

The API will be available at `http://localhost:8000`. 

### Mobile Application (Flutter)

The mobile app is located in the same directory.

1.  **Install dependencies:**
    `flutter pub get`

2.  **Run the app:**
    `flutter run`

**Author:** Ninad Apte
**Email:** ninadapte9@gmail.com
**LinkedIn:** https://www.linkedin.com/in/ninadapte/
