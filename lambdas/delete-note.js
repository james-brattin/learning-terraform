import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const NOTES_TABLE = process.env.NOTES_TABLE;

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

module.exports.handler = async (event, context) => {
  const id = event.body.id;

  const command = new DeleteCommand({
    TableName: NOTES_TABLE,
    Key: {
      noteId: id
    },
  });

  const response = await docClient.send(command);

  return response;
};
