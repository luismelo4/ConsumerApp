import React, { useState, useEffect } from "react";
import {
  Button,
  Typography,
  CircularProgress,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  TablePagination,
  Select,
  MenuItem,
} from "@mui/material";
import { fetchProducts } from "../services/api";

const ProductGrid = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [source, setSource] = useState("sql");
  const [totalCount, setTotalCount] = useState(0);
  const [country, setCountry] = useState(""); // Track the selected country

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const data = await fetchProducts(page, rowsPerPage, source, country);
        setProducts(data.products);
        setTotalCount(data.total_count);
      } catch (error) {
        console.error("Error fetching products:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [page, rowsPerPage, source, country]);

  return (
    <div>
      <Typography variant="h4">Products</Typography>

      <div style={{ marginBottom: 20, display: "flex", gap: 10 }}>
        <Button
          variant="contained"
          color={source === "sql" ? "primary" : "default"}
          onClick={() => setSource("sql")}
        >
          SQL Products
        </Button>
        <Button
          variant="contained"
          color={source === "mongo" ? "secondary" : "default"}
          onClick={() => setSource("mongo")}
        >
          Mongo Products
        </Button>
        <Select
          value={country}
          onChange={(e) => setCountry(e.target.value)}
          displayEmpty
          style={{ width: 150 }}
        >
          <MenuItem value="">All Countries</MenuItem>
          <MenuItem value="belgium">Belgium</MenuItem>
          <MenuItem value="FR">France</MenuItem>
          <MenuItem value="DE">Germany</MenuItem>
        </Select>
      </div>

      {loading ? (
        <CircularProgress />
      ) : (
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Product Name</TableCell>
              <TableCell>Price</TableCell>
              <TableCell>Brand</TableCell>
              <TableCell>Country</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {products.map((product) => (
              <TableRow key={product.id}>
                <TableCell>{product.product_name}</TableCell>
                <TableCell>{product.price}</TableCell>
                <TableCell>{product.brand}</TableCell>
                <TableCell>{product.country}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}

      <TablePagination
        rowsPerPageOptions={[10, 25, 50]}
        component="div"
        count={totalCount}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={(e, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
      />
    </div>
  );
};

export default ProductGrid;