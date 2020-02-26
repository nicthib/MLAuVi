# mlauvi: An audiovisualization tool for neuroimaging datasets

## Introduction

MatLab AUdioVIsualizer (MLAUVI) is a tool that can create beautiful audiovisualizations of neuroimaging (and other) datasets. MLAUVI allows you to adjust a variety of parameters to create an effective audiovisualization, and even allows you to save settings if you want to tweak parameters in the future.

### Requirements:
- MATLAB (2017 or later - previous versions have not been tested)
- ffmpeg (required for combined audio/video files)
- Some data (example data is included to help you get yours into the proper format)

## Installation

1. Clone or download this repository.
2. Make sure you have ffmpeg installed.
    - For mac/linux, ffmpeg can be easily installed using brew: `brew install ffmpeg`
    - For windows, you can [follow this guide](https://github.com/adaptlearning/adapt_authoring/wiki/Installing-FFmpeg) for a straightforward installation.
3. In order to point Matlab to your ffmpeg installation, first navigate to the `mlauvi` folder and then input:
    - (mac/linux) if installed with brew, run `readlink $(which ffmpeg) > ffmpegpath.txt`. Otherwise, `which ffmpeg > ffmpegpath.txt` should work.
    - (windows) `where ffmpeg > ffmpegpath.txt`
4. Open and run `mlauvi.m`. Make sure to select "Add to Path" if prompted.
5. You are now ready to create some cool audiovisualizations!

## Navigating the GUI
