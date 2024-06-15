import OpenAI from 'openai';
import fs from 'fs';
import express from 'express';
import multer from 'multer';
import os from 'os';

const openai = new OpenAI();
const app = express();

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, os.tmpdir()); // Store files in the system's temporary directory
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ storage });

const transcribeAudio = async (filePath) => {
  const transcription = await openai.audio.transcriptions.create({
    file: fs.createReadStream(filePath),
    model: "whisper-1"
  });

  console.log(transcription);

  return transcription
};

app.post('/upload-audio', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return res.status(400).send({ success: false, error: 'No audio file uploaded' });
  }

  const filePath = req.file.path;
  const transcription = await transcribeAudio(filePath);
  res.send({success: true, text: transcription.text});
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
