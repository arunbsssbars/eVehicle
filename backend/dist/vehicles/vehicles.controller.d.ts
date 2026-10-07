export declare class VehiclesController {
    private vehiclesByTenant;
    findAll(tenantId: string): {
        success: boolean;
        tenantId: string;
        data: any[];
    };
    create(tenantId: string, body: any): {
        success: boolean;
        data: any;
    };
    findOne(tenantId: string, id: string): {
        success: boolean;
        data: any;
    };
}
