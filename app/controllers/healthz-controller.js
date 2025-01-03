const sequelize = require('../db.js');

const gethealthz = async (request, response) => {
  try {
    if (request.body && Object.keys(request.body).length > 0) {
      console.log("No body required");
      console.log(request.body.length);
      console.log(request.body);
      response.status(400).set('Cache-Control', 'no-cache').send();
    }
    else {
      await sequelize.authenticate();
      console.log('Connection has been established successfully.');
      response.status(200).set('Cache-Control', 'no-cache').send();
    }
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    response.status(503).set('Cache-Control', 'no-cache').send();
  }
}

module.exports = { gethealthz };