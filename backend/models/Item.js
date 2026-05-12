const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  category: { type: String, required: true }, // 'Book' or 'Stationery'
  condition: { type: String, required: true }, // 'New' or 'Used'
  priceType: { type: String, required: true }, // 'Free' or '₹Amount'
  description: { type: String, required: true },
  imageUrl: { type: String, required: true }, // Base64 string
  postedBy: { type: String, required: true }, // 'Senior', 'Junior', 'Staff'
  ownerEmail: { type: String, required: true },
  postedDate: { type: Date, default: Date.now },
  status: { 
    type: String, 
    enum: ['available', 'pendingMeetup', 'sold'], 
    default: 'available' 
  },
  pendingBuyerEmail: { type: String, default: null },
  soldToBuyerEmail: { type: String, default: null },
  purchaseTime: { type: Date, default: null },
});

module.exports = mongoose.model('Item', itemSchema);
