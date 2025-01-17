import axios from 'axios';

const API_BASE_URL = "http://localhost:3001/products";  // Make sure this matches your Rails backend

// Fetch products with pagination and source
export const fetchProducts = async (page, perPage, source, country = "") => {
  try {
    const url = `${API_BASE_URL}?page=${page + 1}&per=${perPage}&src=${source}&country=${country}`;
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    console.error("Error fetching products:", error);
    throw error;
  }
};

// Upload file API endpoint
export const uploadFile = async (file) => {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const response = await axios.post(`${API_BASE_URL}/upload_file`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return response.data;
  } catch (error) {
    console.error("Error uploading file:", error);
    throw error;
  }
};
