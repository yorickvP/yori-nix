with (import <secrets>).hostnames; {
	network.description = "yorick's stuff";
	frumar = {
		imports = [./frumar/configuration.nix];
		deployment.targetHost = frumar;
	};
	pennyworth = {
		imports = [./pennyworth/configuration.nix];
		deployment.targetHost = pennyworth;
	};
	woodhouse = {
		imports = [./woodhouse/configuration.nix];
		deployment.targetHost = woodhouse;
	};
}
