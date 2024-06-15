import OpenAI from "openai";
import express from 'express';
import multer from 'multer';

const openai = new OpenAI();

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

app.post('/upload-audio', upload.single('audio'), (req, res) => {
  if (!req.file) {
    return res.status(400).send('No audio file uploaded.');
  }
  console.log('Received audio file:', req.file.originalname);
  res.send('Audio file uploaded successfully.');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

