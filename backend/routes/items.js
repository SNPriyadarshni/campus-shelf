const express = require('express');
const router = express.Router();
const Item = require('../models/Item');
const auth = require('../middleware/auth');

// Get all items (with filters and search)
router.get('/', async (req, res) => {
  try {
    const { category, freeOnly, search, userEmail } = req.query;
    let query = {};

    if (category && category !== 'All') {
      query.category = category;
    }

    if (freeOnly === 'true') {
      query.priceType = 'Free';
    }

    if (userEmail) {
      query.ownerEmail = userEmail;
    }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const items = await Item.find(query).sort({ postedDate: -1 });
    res.json(items);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get item by ID
router.get('/:id', async (req, res) => {
  try {
    const item = await Item.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ message: 'Item not found' });
    }
    res.json(item);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Create item
router.post('/', auth, async (req, res) => {
  try {
    const newItem = new Item({
      ...req.body,
      postedDate: new Date(),
    });

    const item = await newItem.save();
    res.json(item);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Delete item
router.delete('/:id', auth, async (req, res) => {
  try {
    const item = await Item.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ message: 'Item not found' });
    }

    await item.deleteOne();
    res.json({ message: 'Item removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Update item status (e.g., mark as sold)
router.patch('/:id/status', auth, async (req, res) => {
  try {
    const { status, buyerEmail } = req.body;
    const id = req.params.id;

    let update = { status };
    let query = { _id: id };

    if (status === 'sold') {
      // ATOMIC UPDATE: Only update if the item is currently 'available'
      // This prevents double-buying
      query.status = 'available';
      if (buyerEmail) {
        update.soldToBuyerEmail = buyerEmail;
        update.purchaseTime = new Date();
      }
    } else if (status === 'pendingMeetup' && buyerEmail) {
      update.pendingBuyerEmail = buyerEmail;
    }

    const item = await Item.findOneAndUpdate(query, update, { new: true });

    if (!item) {
      // If item is not found with 'available' status when trying to buy
      if (status === 'sold') {
        const checkItem = await Item.findById(id);
        if (checkItem && checkItem.status === 'sold') {
          return res.status(409).json({ message: 'This item is already sold out' });
        }
      }
      return res.status(404).json({ message: 'Item not found or unavailable' });
    }

    res.json(item);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;

