// server.js
const express = require('express');
const app = express();
const port = process.env.PORT || 5000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from PR Deploy!',
    VITE_API_URL: process.env.VITE_API_URL,
    NODE_ENV: process.env.NODE_ENV
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
