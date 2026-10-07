export declare class ApprovalsController {
    findPending(): {
        success: boolean;
        data: any[];
    };
    approve(id: string): {
        success: boolean;
        data: {
            id: string;
            status: string;
            approvedAt: string;
        };
    };
    reject(id: string, reason: string): {
        success: boolean;
        data: {
            id: string;
            status: string;
            reason: string;
            rejectedAt: string;
        };
    };
    lock(id: string): {
        success: boolean;
        data: {
            id: string;
            status: string;
            lockedAt: string;
        };
    };
}
