export declare class AppController {
    getRoot(): {
        success: boolean;
        service: string;
        version: string;
        status: string;
        docs: string;
        endpoints: {
            vehicles: string;
            journeys: string;
            approvals: string;
            reports: string;
            auth: string;
        };
        timestamp: string;
    };
    getHealth(): {
        status: string;
        uptime: number;
        timestamp: string;
    };
}
