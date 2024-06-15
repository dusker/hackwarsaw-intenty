import OpenAI from 'openai';
import fs from 'fs';
import express from 'express';
import multer from 'multer';
import os from 'os';

const openai = new OpenAI();
const app = express();
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, os.tmpdir());
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});
const upload = multer({ storage });

const sendError = (res, error) => {
  res.status(500)
    .send({success: false, error: error.message});
};

const extractProductList = async (transcription) => {
  const completion = await openai.chat.completions.create({
    messages: [
      { role: "system", content: PROMPT },
      { role: "user", content: transcription },
    ],
    model: "gpt-4o",
  });
  
  return completion.choices[0].message.content;
};

const transcribeAudio = async (filePath) => {
  const transcription = await openai.audio.transcriptions.create({
    file: fs.createReadStream(filePath),
    model: "whisper-1"
  });

  return transcription
};

app.post('/upload-audio', upload.single('audio'), async (req, res) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET,PUT,PATCH,POST,DELETE");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  if (!req.file) {
    const error = {message: 'No audio file uploaded'};
    sendError(res, error);
    return;      
  }
  const filePath = req.file.path;
  console.log(`Will extract products from file at ${filePath}`);  
  try {    
    const transcription = await transcribeAudio(filePath);
    console.log(`Transcription: ${transcription.text}`);
    const products = await extractProductList(transcription.text);    
    console.log(`Products: ${products}`);
    res.send({success: true, products: JSON.parse(products)});
  } catch(error) {
    sendError(res, error);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

const PROMPT = `\
You are an assistant who helps people sort their groceries. \
You'll receive a transcription with user saying what products they purchased. \
Your task is to extract all products and the expiry dates they mentioned. \
You should return everything as a json array containing objects in following format: \
{ \
  "product": The product title \
  "expiry_timestamp": Time interval in seconds since 1970 representing the expiry date of the given product \
  "expiry_date": Human readable expiration date of the product containing day, month and year \
  "trigger": Exact words the user said which reference the product and expiry date \
  "emoji": An emoji representing the product \
} \
Return only valid json without any formatting. Any relative dates mentioned by the user should \
use the following date as a reference point: ${new Date()}
`
