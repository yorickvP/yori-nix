with (import <secrets>).hostnames; {
	network.description = "yorick's stuff";
	ospinio = {
		imports = [./ospinio/configuration.nix];
		deployment.targetHost = ospinio;
	};
	frumar = {
		imports = [./frumar/configuration.nix];
		deployment.targetHost = frumar;
	};
}
