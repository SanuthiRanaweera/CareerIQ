const chatbotService = require('../services/chatbotService');

async function sendMessage(req, res, next) {
  try {
    const data = await chatbotService.sendMessage(req.user.userId, req.body.message, req.body.mode);
    return res.json({ success: true, data });
  } catch (error) {
    return next(error);
  }
}

async function getHistory(req, res, next) {
  try {
    const messages = await chatbotService.getHistory(req.user.userId);
    return res.json({ success: true, data: messages });
  } catch (error) {
    return next(error);
  }
}

module.exports = { sendMessage, getHistory };
