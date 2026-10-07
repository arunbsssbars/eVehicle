export declare class AuthController {
    login(body: any): {
        success: boolean;
        data: {
            accessToken: string;
            refreshToken: string;
            user: {
                id: string;
                name: string;
                email: any;
                role: string;
                department: string;
                office: string;
            };
        };
    };
    register(body: any): {
        success: boolean;
        data: {
            message: string;
            userId: string;
        };
    };
    verifyOtp(body: any): {
        success: boolean;
        data: {
            accessToken: string;
            verified: boolean;
        };
    };
}
