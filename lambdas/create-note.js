import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

const NOTES_TABLE = process.env.NOTES_TABLE; // obtaining the table name

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

module.exports.handler = async (event, context) => {
  //const body = event.body;

  const command = new PutCommand({
    TableName: NOTES_TABLE,
    Item: {
      noteId: Date.now(),
    }
  });

  const response = await docClient.send(command);

  return response;
};
