const express = require('express');
const app = express();
const port = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.send('Hello from mon-app!');
});

app.listen(port, () => {
  console.log(`mon-app listening on port ${port}`);
});
