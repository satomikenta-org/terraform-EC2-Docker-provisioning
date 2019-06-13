const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());

app.get('/', (req, res) => {
  res.send('OK');
})

app.listen(3000, () => {
  console.log('server running on port 3000');
});