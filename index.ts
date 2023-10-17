import { ActivityPartial, Client } from "@projectdysnomia/dysnomia";
import { consola as log } from "consola";

interface Config {
    dev: boolean;
    token: string;
    ownerid: string;
};

import c from "./config.toml";
const config = c as Config;

import s from "./status.toml";
const { status } = s as { status: ActivityPartial[] };

const client = new Client(config.token, {
    gateway: {
        intents: [
            "guildMessages"
        ]
    }
});

function randomValue<T>(arr: T[]): T {
    return arr[Math.floor(Math.random() * (arr.length + 1))];
}

client.on("ready", () => {
    log.ready("Purr... Watching over Termux server. -ω-");
    client.editStatus("online", randomValue<ActivityPartial>(status));
});

client.connect();
