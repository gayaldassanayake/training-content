import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/nats;

type DBConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DBConfig dbConfig = ?;

isolated final mysql:Client forumDBClient = check initDbClient();

function initDbClient() returns mysql:Client|error => new (...dbConfig);

configurable SentimentClientConfig sentimentClientConfig = ?;

type SentimentClientConfig record {|
    string clientUrl;
    string refreshUrl;
    string refreshToken;
    string clientId;
    string clientSecret;
|};

@display {
    label: "Sentiment Analysis Client",
    id: "sentiment-analysis"
}
final http:Client sentimentClient = check initSentimentClient();

function initSentimentClient() returns http:Client|error => new (sentimentClientConfig.clientUrl,
    secureSocket = {
        cert: "resources/server_public.crt",
        'key: {
            certFile: "resources/client_public.crt",
            keyFile: "resources/client_private.key"
        }
    },
    auth = {
        refreshUrl: sentimentClientConfig.refreshUrl,
        refreshToken: sentimentClientConfig.refreshToken,
        clientId: sentimentClientConfig.clientId,
        clientSecret: sentimentClientConfig.clientSecret,
        clientConfig: {
            secureSocket: {
                cert: "resources/sts_server_public.crt"
            }
        }
    },
    retryConfig = {
        interval: 1,
        count: 3,
        statusCodes: [503]
    }
);

@display {
    label: "NATS Notification Publisher",
    id: "nats-notifier"
}
final nats:Client natsClient = check initNatsClient();

function initNatsClient() returns nats:Client|error => new (nats:DEFAULT_URL);
