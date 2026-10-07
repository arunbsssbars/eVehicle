export interface RequestUser {
    id: string;
    name: string;
    email: string;
    role: string;
    tenantId: string;
    department?: string;
}
export declare const CurrentUser: (...dataOrPipes: unknown[]) => ParameterDecorator;
