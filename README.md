# ConsumerApp & ConsumerApi

This repository contains the backend (`ConsumerApi`) and frontend (`ConsumerUI`) of the **ConsumerApp**

## Overview

The project involves two primary components:

- **ConsumerApi**: The backend responsible for importing, processing, and storing JSON data, while providing an API for the frontend to fetch the necessary data. It supports high-volume data handling and optimizations such as background jobs and pagination.
- **ConsumerUI**: The frontend built with React, allowing users to interact with and visualize the product data provided by the backend.

## Key Features

- **Data Import**: The backend processes and stores product data, which includes country, brand, SKU, model, site or marketplace seller, categoryId, price, and URL, filtering out data with availability `false` or price <= 0.
- **Batch Processing**: The producer uses the **OJ** library to stream JSON files in batches, while the consumer processes these batches to insert the data into both MongoDB and SQL Server.
- **Temp Tables for Merge**: A temporary table approach is used for data merging. Redis is used to track the status of the jobs and ensure proper synchronization for the final truncation step after merging.
- **Character Encoding**: All data is encoded in UTF-8 to ensure compatibility and prevent issues with special characters.
- **URL Handling**: URLs are escaped directly, bypassing the ORM to ensure proper encoding.

## Setup

### Prerequisites

- Ruby (for **ConsumerApi**)
- Node.js (for **ConsumerUI**)
- MongoDB (for storing product data)
- SQL Server (for additional data storage)
- Redis (for job synchronization)

### Running the Project Locally

1. **ConsumerApi (Backend)**

   Navigate to the **ConsumerApi** directory and run the Rails server:

   ```bash
   rails -s -p 3001
