export declare class ReportsController {
    getMonthlyReport(month: string, vehicleId: string): {
        success: boolean;
        data: {
            month: string;
            vehicleId: string;
            totalJourneys: number;
            totalDistanceKm: number;
            totalFuelLiters: number;
            fuelCost: number;
        };
    };
    getDailyReport(date: string): {
        success: boolean;
        data: {
            date: string;
            totalTrips: number;
            totalDistanceKm: number;
        };
    };
}
