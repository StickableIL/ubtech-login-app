const express = require('express');
const sql = require('mssql');
const bcrypt = require('bcryptjs');
const app = express();

app.use(express.json());
require('dotenv').config();
console.log('DB_SERVER:', process.env.DB_SERVER);

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true,
    trustServerCertificate: true 
  }
};

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  console.log('DB_SERVER:', process.env.DB_SERVER);
  try {
    await sql.connect(config);
    const result = await sql.query`SELECT * FROM Users WHERE Username = ${username}`;

    if (result.recordset.length > 0) {
      const user = result.recordset[0];
      const isValidPassword = await bcrypt.compare(password, user.Password);

      if (isValidPassword) {
        res.send({ message: "Login successful", username: user.Username });
      } else {
        res.status(401).send({ message: "Invalid username or password" });
      }
    } else {
      res.status(401).send({ message: "Invalid username or password" });
    }
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: "An error occurred. Please try again later." });
  }
});

app.post('/api/signup', async (req, res) => {
  const { username, password } = req.body;

  try {
    await sql.connect(config);
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await sql.query`INSERT INTO Users (Username, Password) VALUES (${username}, ${hashedPassword})`;
    res.status(201).send({ message: 'User created successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).send({ message: 'Error registering the user' });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});