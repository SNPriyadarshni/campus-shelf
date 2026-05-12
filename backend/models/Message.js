const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  itemId: { type: String, required: true },
  itemName: { type: String, required: true },
  senderEmail: { type: String, required: true },
  senderName: { type: String, required: true },
  ownerEmail: { type: String, required: true },
  receiverEmail: { type: String }, // New field for two-way chat
  message: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  isRead: { type: Boolean, default: false },
});

module.exports = mongoose.model('Message', messageSchema);
