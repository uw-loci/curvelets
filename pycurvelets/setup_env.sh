#!/bin/bash

# Set virtual environment named "pycurvelets"
ENV_NAME="pycurvelets"

# Make sure Conda's installed first
if ! command -v conda &> /dev/null; then
    echo "Conda is not installed. Please install Miniconda or Anaconda first."
    exit 1
fi

# Create virtual environment if "pycurvelets" does not exist
if ! conda info --envs | grep -q "^$ENV_NAME\s"; then
    echo "Creating conda environment: $ENV_NAME"
    conda create -y -n "$ENV_NAME" python=3.10
fi

# Activate environment
echo "Activating conda environment: $ENV_NAME"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"


# Change this to where the absolute path to these files are
echo "Setting environment variables..."
export FFTW=~/opt/fftw-2.1.5
export FDCT=~/opt/CurveLab-2.1.3

echo "Installing Python dependencies..."
pip install -r requirements.txt