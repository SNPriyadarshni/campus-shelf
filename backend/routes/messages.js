const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const auth = require('../middleware/auth');

// Get messages for user
router.get('/', auth, async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) {
      return res.status(400).json({ message: 'Email required' });
    }

    const messages = await Message.find({
      $or: [
        { senderEmail: email }, 
        { receiverEmail: email },
        { ownerEmail: email } // Keep for backward compatibility
      ]
    }).sort({ timestamp: -1 });

    res.json(messages);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get messages for specific item
router.get('/item/:itemId', auth, async (req, res) => {
  try {
    // Ensure itemId is a string
    const itemId = req.params.itemId;
    const messages = await Message.find({ itemId: itemId }).sort({ timestamp: 1 });
    res.json(messages);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Send message
router.post('/', auth, async (req, res) => {
  try {
    const newMessage = new Message({
      ...req.body,
      timestamp: new Date(),
    });

    const message = await newMessage.save();
    res.json(message);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
