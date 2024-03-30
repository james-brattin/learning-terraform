import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { BatchGetCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

const NOTES_TABLE = process.env.NOTES_TABLE;

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

module.exports.handler = async (event, context) => {

  const command = new BatchGetCommand({
    RequestItems: {
      NOTES_TABLE: {
        Keys: [
          {
            noteId: "*"
          }
        ]
      }
    }
  });

  const response = await docClient.send(command);

  return response;
};
