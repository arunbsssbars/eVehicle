export declare class JourneysController {
    private journeysByTenant;
    findAll(tenantId: string): {
        success: boolean;
        tenantId: string;
        data: any[];
    };
    startJourney(tenantId: string, body: any): {
        success: boolean;
        data: any;
    };
    completeJourney(tenantId: string, id: string, body: any): {
        success: boolean;
        error: {
            code: string;
            message: string;
        };
        data?: undefined;
    } | {
        success: boolean;
        data: {
            id: string;
            tenantId: string;
            officialDistance: number;
            status: string;
        };
        error?: undefined;
    };
}
