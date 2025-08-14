# Aerosol Optical Depth (AOD) Analysis for Maharashtra

This project is a Python-based implementation of the methodology described in the research paper **"An Improved High-Resolution AOD-PM2.5 Relationship Using Ground-Based Observations and Satellite-Derived Datasets"** to analyze Aerosol Optical Depth (AOD) and its relationship with PM2.5 concentrations, with a specific focus on the Maharashtra region of India.

The implementation uses satellite data from NASA's Terra/Aqua (MAIAC) and meteorological data from MERRA-2 to replicate the data fusion and analysis process outlined in the paper.

---

## Core Objective

The goal of this project is to process, align, and analyze multiple satellite and meteorological datasets to study air quality. This involves:
1.  **Downloading** required MAIAC AOD and MERRA-2 meteorological data for a specific time and region.
2.  **Preprocessing** the raw HDF and NetCDF data files.
3.  **Extracting** relevant variables (like AOD, Planetary Boundary Layer Height, Relative Humidity, Wind Speed).
4.  **Aligning** the datasets spatially and temporally.
5.  **Visualizing** the results, such as the average AOD over the study area.

---

## Prerequisites

Before you begin, ensure you have the following set up:

1.  **Python Environment**: Python 3.7 or higher. Using an environment manager like `conda` or `venv` is highly recommended.
2.  **Required Python Libraries**:
    ```bash
    pip install numpy pandas geopandas xarray matplotlib tqdm pyhdf jupyterlab
    ```
3.  **NASA Earthdata Account**: You **must** have a registered account on the [NASA Earthdata portal](https://urs.earthdata.nasa.gov/users/new). This is required to download the satellite data.

---

## Step-by-Step Implementation Guide

Follow these steps to reproduce the analysis.

### Step 1: Set Up Earthdata Credentials

For the download scripts to work, you must authorize access to the NASA Earthdata archives.

1.  After creating your Earthdata account, create a file named `.netrc` in your system's home directory.
    * **On Linux/macOS**: `~/.netrc`
    * **On Windows**: `C:\Users\<YourUsername>\.netrc`
2.  Add the following lines to this file, replacing `<YourUsername>` and `<YourPassword>` with your actual Earthdata credentials:
    ```
    machine urs.earthdata.nasa.gov
    login <YourUsername>
    password <YourPassword>
    ```
3.  Next, create a file named `.urs_cookies` in your home directory. You can leave this file empty. This helps in managing authentication cookies.

### Step 2: Download the Datasets

This project uses shell scripts to download the necessary data.

1.  **MAIAC AOD Data**: Run the `maiac-download-updated.sh` script to download the MCD19A2 data product. This script is pre-configured for the required date range and geographical tiles covering Maharashtra.
    ```bash
    bash maiac-download-updated.sh
    ```
2.  **MERRA-2 Meteorological Data**: Run the `merra-download-updated.sh` script to download the M2T1NXAER data product.
    ```bash
    bash merra-download-updated.sh
    ```
    These scripts will create directories (`MAIAC_Data`, `MERRA2_Data`) and populate them with the raw `.hdf` and `.nc4` files from the NASA servers.

### Step 3: Run the Analysis Notebook

The core logic for data processing and analysis is contained in the `PHASE_1_and_PHASE_2.ipynb` Jupyter Notebook.

1.  Launch Jupyter Lab in your terminal:
    ```bash
    jupyter lab
    ```
2.  Open the `PHASE_1_and_PHASE_2.ipynb` notebook.
3.  Execute the cells in the notebook sequentially from top to bottom.

#### What the Notebook Does:
* **Phase 1**:
    * Reads all the downloaded MAIAC (`.hdf`) and MERRA-2 (`.nc4`) files.
    * Extracts key variables: AOD, PBLH, RH, U-wind, V-wind.
    * Performs initial preprocessing and alignment.
    * Saves the processed data into intermediate `.csv` files for easier access later.
* **Phase 2**:
    * Loads the processed data from the `.csv` files.
    * Conducts further cleaning and unit conversions.
    * Performs the final analysis, including calculating daily averages.
    * Generates visualizations, such as a map of the average AOD across Maharashtra.

---

## Project File Structure

```
.
├── Aerosol-Optical-Depth/
│   ├── PHASE_1_and_PHASE_2.ipynb      # Main analysis notebook
│   ├── maiac-download-updated.sh      # Script to download MAIAC AOD data
│   ├── merra-download-updated.sh      # Script to download MERRA-2 data
│   ├── Research Paper.pdf             # The original research paper
│   ├── README.md                      # This file
│   └── (Generated) MAIAC_Data/        # Directory for raw MAIAC files
│   └── (Generated) MERRA2_Data/       # Directory for raw MERRA-2 files
│   └── (Generated) phase1_output.csv  # Intermediate processed data
└── ...
```

---

## Expected Outcome

After running the notebook successfully, you will have generated intermediate data files and visualizations. The final output cell in the Jupyter Notebook will display a plot showing the spatial distribution of the average Aerosol Optical Depth over the Maharashtra region for the specified study period, similar to the analysis in the reference paper.
