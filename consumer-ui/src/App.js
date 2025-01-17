import React, { useState } from "react";
import { QueryClient, QueryClientProvider } from "react-query";
import FileUpload from "./components/FileUpload";
import ProductGrid from "./components/ProductGrid";
import { Container } from "@mui/material";

const queryClient = new QueryClient();

const App = () => {
  const [country] = useState("");

  return (
    <QueryClientProvider client={queryClient}>
      <Container>
        <h1>Consumer UI</h1>
        <FileUpload onUploadComplete={() => queryClient.invalidateQueries("products")} />
        <ProductGrid country={country} />
      </Container>
    </QueryClientProvider>
  );
};

export default App;
