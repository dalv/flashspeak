/// The situations offered for suggested phrases (PRD, Suggested categories).
enum SuggestCategories {
    struct Group: Identifiable {
        var id: String {
            title
        }

        let title: String
        let categories: [String]
    }

    static let groups: [Group] = [
        Group(title: "Everyday", categories: [
            "Greetings and small talk", "Meeting someone at a party", "Talking about yourself",
            "Making plans with friends", "Texting and chat replies",
        ]),
        Group(title: "Out and about", categories: [
            "At the grocery store", "At a café or restaurant", "At the market (bargaining)",
            "Getting and giving directions", "Taxi or ride-hail", "Public transport",
        ]),
        Group(title: "Services", categories: [
            "At the pharmacy or doctor", "At the bank or ATM", "Phone and SIM card",
            "At the hair salon", "Dealing with a repair person",
        ]),
        Group(title: "Places", categories: [
            "At the gym", "At the hotel or guesthouse", "Renting an apartment", "At the airport",
        ]),
        Group(title: "Social", categories: [
            "Compliments and thanks", "Apologising and small problems", "Asking for help",
            "Agreeing and disagreeing", "“One more time, slowly please”",
        ]),
        Group(title: "Emergencies", categories: [
            "Lost items", "Feeling unwell", "Asking for the police or an ambulance",
        ]),
    ]
}
